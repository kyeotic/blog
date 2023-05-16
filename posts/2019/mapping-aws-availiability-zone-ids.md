---
title: "Getting AWS Availability Zone IDs with Terraform"
pathname: "/mapping-aws-availiability-zone-ids"
publish_date: 2019-05-31
tags: ["aws", "terraform", "gist"]
---

AWS Availability Zone names may look like unique identifiers, but they are [mapped to physical availability zones essentially at *random*](https://docs.aws.amazon.com/ram/latest/userguide/working-with-az-ids.html). This means that **us-west-2b** in one account may be the same physical availability zone as **us-west-2a** in another account.

If you are doing certain kinds of cross-account networking mapping by name can result in errors. To solve this AWS provides the **ID** of the availability zone, which *will* map to the same physical availability zone in every account. They don't make it easy though: it's hidden away inside the [**Resource Access Manager**]( https://console.aws.amazon.com/ram).

 Luckily, if you are using terraform you can easily get the the availability zone ID as a value by mapping it against the [aws_availability_zones data resource](https://www.terraform.io/docs/providers/aws/d/availability_zones.html). Here is an example using a *VPC Service Endpoint*.

```hcl
data "aws_availability_zones" "available" {}

output "service_provider_zone_ids" {
  description = "Availability Zone IDs of the Provider"

  value = "${matchkeys(
    data.aws_availability_zones.available.zone_ids,
    data.aws_availability_zones.available.names,
    aws_vpc_endpoint_service.service_provider.availability_zones
  )}"
}
```
