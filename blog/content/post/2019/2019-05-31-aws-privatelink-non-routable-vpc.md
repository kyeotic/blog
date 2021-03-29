---
title: "Configuring AWS PrivateLink in non-routable VPCs Consumers with Terraform"
url: "/aws-privatelink-non-routable-vpc"
date: "2019-05-31"
lastmod: "2019-06-02"
tags: ["aws", "vpc", "privatelink", "terraform"]
---

[AWS VPC](https://docs.aws.amazon.com/vpc/latest/userguide/getting-started-ipv4.html)s make it possible to establish private network connections across AWS accounts with [VPC Peering](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-peering.html), essentially merging the networks into one. However, there is another option for cross-account/cross-VPC network access, with a much smaller surface area.

PrivateLink is a bundle of services with some [difficult-to-parse documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpce-interface.html), but it's pretty powerful. Today I'm just going to cover a single use case: communicating between a central *service provider* to a set of *consumers*, living in non-routable VPC's (no NAT gateway, no internet gateway, no public/elastic IPs), all in various AWS accounts.

This is great if you have a dynamic fleet of publishers with incredibly sensitive payloads, since there is no attack surface. They won't be able to talk to the internet, and the internet won't be able to talk to them. You won't run out of IP addresses either.

## Overview

There are two halves.

- In the **Service Provider **account we will setup a **VPC Service Endpoint** and a **Network Load Balancer **pointing to an Ec2 Instance. 
- In the **Consumer** account we will setup a **non-routable VPC **and a **VPC Endpoint**.

The **Consumer** account setup can be repeated against the same **Service Provider Endpoint**. As a bonus, after we have it setup we will look at handling HTTPS/TLS. This is important if your service provider is pulling double duty as a Public service, as mine was, because HTTPS redirection doesn't play nicely with the standard setup for VPC Endpoints.

I'm going to be providing terraform code throughout this post, with variables that you either need to provide from existing infrastructure or define for this module. Variables that start with `existing_` are for resources that exist, and variables that start with `your_` are for resources to-be-created (so pick whatever value).

## Service Provider Setup

Since this isn't about the service itself, I'm not going to cover setting up an EC2 instance, or the VPC that the provider uses. I'll just show you the setup for the *Service Endpoint *and related setup.

The following data resources will be used, assuming existing infrastructure

    data "aws_vpc" "provider" {
      id = "${var.existing_provider_vpc_id}"
    }

First we need a *Network Load Balancer* (NLB) that targets the Ec2 instance. **NOTE:** you **cannot** use an ALB/ELB, as *service endpoints* only support NLBs

    resource "aws_lb" "link" {
      name               = "${var.your_nlb_name}"
      internal           = true
      load_balancer_type = "network"
      subnets            = ["${var.existing_target_subnet_id}"]
    }
    
    resource "aws_lb_target_group" "link_http" {
      name     = "${}"
      port     = 80
      protocol = "TCP"
      vpc_id   = "${data.aws_vpc.provider.id}"
    
      stickiness = {
        type    = "lb_cookie"
        enabled = false
      }
    }
    
    resource "aws_lb_target_group_attachment" "link_http" {
      target_group_arn = "${aws_lb_target_group.link_http.arn}"
      target_id        = "${local.target_instance}"
      port             = 80
    }
    
    resource "aws_lb_listener" "link_http" {
      load_balancer_arn = "${aws_lb.link.arn}"
      port              = "80"
      protocol          = "TCP"
    
      default_action {
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.link_http.arn}"
      }
    }

This is the terraform for the *VPC**Service Endpoint*.

    resource "aws_vpc_endpoint_service" "service_provider" {
      network_load_balancer_arns = ["${aws_lb.link.arn}"]
      allowed_principals         = ["${var.consumer_principals}"]
      acceptance_required        = false
    }
    
    # you probably want to include these for reference
    output "service_provider_name" {
      description = "The name of VPC Endpoint Service"
      value       = "${aws_vpc_endpoint_service.service_provider.service_name}"
    }
    
    output "service_provider_zones" {
      description = "Availability Zones of the Provider"
      value       = "${aws_vpc_endpoint_service.service_provider.availability_zones}"
    }

The *outputs* are going to be needed in the *consumer* configuration, make sure you write them down.

For cross-VPC communication the *Service Endpoint*needs to be in the same *physical* availability zone as the *consumer Endpoint*. The gotcha here is that the [name given to availability zones in each AWS account is essentially *random*](https://docs.aws.amazon.com/ram/latest/userguide/working-with-az-ids.html) (probably to help balance out the physical distribution when everyone probably uses `us-east-1a`). Which means you can't rely on the **name**, you need the **AZ ID**. To get that you can [use a terraform data resource to look it up](/mapping-aws-availiability-zone-ids/) and another output to read it.

    data "aws_availability_zones" "available" {}
    
    output "service_provider_zone_ids" {
      description = "Availability Zone IDs of the Provider"
    
      value = "${matchkeys(
        data.aws_availability_zones.available.zone_ids,
        data.aws_availability_zones.available.names,
        aws_vpc_endpoint_service.service_provider.availability_zones
      )}"
    }
    

## Consumer Setup

Since our consumer will be a new service we will define

- A **new VPC** with **private subnets**
- Security groups with ingress and egress rules
- A **VPC Endpoint** (this is the consumer half of the provider's *service endpoint*)

    locals {
      # Private IP address space
      vpc_cidr_block            = "10.0.0.0/16"
      vpc_private_subnet_blocks = ["10.0.1.0/24"]
    }
    
    resource "aws_vpc" "consumer" {
      cidr_block           = "${local.vpc_cidr_block}"
      enable_dns_support   = true
      enable_dns_hostnames = true
    
      tags = {
        "Name" = "${var.your_consumer_vpc_name}"
      }
    }
    
    resource "aws_route_table" "consumer" {
      count = "${length(local.vpc_private_subnet_blocks)}"
    
      vpc_id = "${aws_vpc.consumer.id}"
    }
    
    resource "aws_subnet" "consumer" {
      vpc_id               = "${aws_vpc.consumer.id}"
      cidr_block           = "${element(local.vpc_private_subnet_blocks, 0)}"
      # This is the output var from the provider setup
      availability_zone_id = "${var.existing_vpc_availability_zone_id}"
    
      tags = {
        "Name" = "${var.your_consumer_vpc_name}"
      }
    }
    
    resource "aws_default_security_group" "default" {
      vpc_id = "${aws_vpc.consumer.id}"
    }
    
    resource "aws_security_group" "endpoint_services" {
      name        = "_endpoint_services"
      description = "Allows traffic for endpoint services"
      vpc_id      = "${aws_vpc.consumer.id}"
    
      tags = {
        "Name" = "${var.your_consumer_vpc_name} - Endpoint Services"
        "Type" = "endpoint_services"
      }
    }
    
    resource "aws_security_group_rule" "endpoint_services_ingress_80" {
      type      = "ingress"
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
    
      cidr_blocks = [
        "${aws_vpc.consumer.cidr_block}",
      ]
    
      security_group_id = "${aws_security_group.endpoint_services.id}"
    }
    
    resource "aws_security_group_rule" "endpoint_services_ingress_443" {
      type      = "ingress"
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
    
      cidr_blocks = [
        "${aws_vpc.consumer.cidr_block}",
      ]
    
      security_group_id = "${aws_security_group.endpoint_services.id}"
    }
    
    # DNS
    resource "aws_security_group_rule" "endpoint_services_egress_53_TCP" {
      type      = "egress"
      from_port = 53
      to_port   = 53
      protocol  = "tcp"
    
      cidr_blocks = [
        "${aws_vpc.consumer.cidr_block}",
      ]
    
      security_group_id = "${aws_security_group.endpoint_services.id}"
    }
    
    resource "aws_security_group_rule" "endpoint_services_egress_53_UDP" {
      type      = "egress"
      from_port = 53
      to_port   = 53
      protocol  = "udp"
    
      cidr_blocks = [
        "${aws_vpc.consumer.cidr_block}",
      ]
    
      security_group_id = "${aws_security_group.endpoint_services.id}"
    }
    
    resource "aws_security_group_rule" "endpoint_services_egress_80" {
      type      = "egress"
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
    
      cidr_blocks = [
        "${aws_vpc.consumer.cidr_block}",
      ]
    
      security_group_id = "${aws_security_group.endpoint_services.id}"
    }
    
    resource "aws_security_group_rule" "endpoint_services_egress_443" {
      type      = "egress"
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
    
      cidr_blocks = [
        "${aws_vpc.consumer.cidr_block}",
      ]
    
      security_group_id = "${aws_security_group.endpoint_services.id}"
    }
    
    resource "aws_vpc_endpoint" "service_consumer" {
      vpc_id     = "${aws_vpc.consumer.id}"
      subnet_ids = ["${aws_subnet.consumer.id}"]
    
      security_group_ids = ["${aws_security_group.endpoint_services.id}"]
    
      # This is the output from the previous section
      service_name       = "${var.existing_service_provider_name}"
      vpc_endpoint_type  = "Interface"
    }

This basic setup will allow communication from our consumer service (such as an AWS Lambda) to our service provider. It does not have any public IP addresses or internet interfaces, which means you cannot talk to anything on the public internet, *including* AWS services. This is probably something you want to do, and luckily its possible to add additional endpoints for AWS services *without connecting to the internet*. Here is an example with STS:

    data "aws_vpc_endpoint_service" "sts" {
      count   = "${data.aws_region.current.name == "us-east-1" ? "0" : "1"}"
      service = "sts"
    }
    
    resource "aws_vpc_endpoint" "sts" {
      count             = "${data.aws_region.current.name == "us-east-1" ? "0" : "1"}"
      vpc_id            = "${aws_vpc.consumer.id}"
      service_name      = "${data.aws_vpc_endpoint_service.sts.service_name}"
      vpc_endpoint_type = "Interface"
    
      security_group_ids = [
        "${aws_security_group.endpoint_services.id}",
      ]
    
      subnet_ids = [
        "${aws_subnet.consumer.id}",
      ]
    
      private_dns_enabled = true
    }

If you don't need to worry about HTTPS/TLS when connecting to your service provider then this is all you need.

## Connecting with HTTPS/TLS

When I set this up my service provider was using an HTTP -> HTTPS redirect, which broke the whole thing. First it broke because I hadn't address 443 egress, but when I did of course the SSL Certificate didn't match up with the consumer VPC endpoint domain, since its an AWS domain.

To get past this I created a new CNAME that pointed to the consumer VPC endpoint, configured AWS Certificate to get an SSL Certificate, and used the new CNAME in my consumer service. 

    data "aws_route53_zone" "base" {
      name = "${var.your_hosted_zone_name}"
    }
    
    resource "aws_route53_record" "consumer" {
      zone_id = "${data.aws_route53_zone.base.zone_id}"
      name    = "consumer-link.${data.aws_route53_zone.base.name}"
      type    = "CNAME"
      ttl     = "300"
      records = ["${aws_vpc_endpoint.service_consumer.dns_entry.1.dns_name}"]
    }
    
    
    provider "aws" {
      region = "us-east-1"
      alias  = "certificates"
    }
    
    # This should match your existing primary AWS provider
    provider "aws" {
      region = "${var.existing_region}"
      alias  = "dns"
    }
    
    module "cert" {
      source = "github.com/azavea/terraform-aws-acm-certificate?ref=1.1.0"
    
      providers = {
        aws.acm_account     = "aws.certificates"
        aws.route53_account = "aws.dns"
      }
    
      domain_name                       = "${aws_route53_record.consumer.name}"
      hosted_zone_id                    = "${data.aws_route53_zone.base.zone_id}"
      validation_record_ttl             = "60"
      allow_validation_record_overwrite = true
    }

[Cover Photo by Isreal Palacio](https://unsplash.com/@othentikisra?utm_source=ghost&utm_medium=referral&utm_campaign=api-credit)
