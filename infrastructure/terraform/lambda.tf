
data "archive_file" "edge" {
  type        = "zip"
  source_file = "${path.module}/${var.lambda_dir}/${var.lambda_name}.js"
  output_path = "${path.module}/${var.lambda_dir}/${var.lambda_name}.js.zip"
}

resource "aws_lambda_function" "edge" {
  function_name = local.lambda_name
  description   = "${local.domain_name} edge lambda"

  # filename         = var.lambda_file
  # source_code_hash = filebase64sha256(var.lambda_file)
  # handler = "export.handler"

  filename         = "${path.module}/${var.lambda_name}.js.zip"
  handler          = "${var.lambda_name}.handler"
  source_code_hash = data.archive_file.edge.output_base64sha256
  provider         = aws.aws_cloudfront

  publish = true
  runtime          = "nodejs10.x"
  role    = aws_iam_role.lambda_at_edge.arn

  lifecycle {
    ignore_changes = [
      last_modified,
    ]
  }
}

data "aws_iam_policy_document" "assume_role_policy_doc" {
  statement {
    sid    = "AllowAwsToAssumeRole"
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "lambda_at_edge" {
  name               = "${local.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_doc.json
}
