provider "aws" {
  region = "us-east-1"
}

variable "bucket_name" {
  default = "angular-reactive-apple1"
}

variable "mime_types" {
  default = {
    htm  = "text/html"
    html = "text/html"
    css  = "text/css"
    ttf  = "font/ttf"
    js   = "application/javascript"
    map  = "application/javascript"
    json = "application/json"
    ico  = "image/x-icon"
  }
}

locals {
  upload_directory = "${path.cwd}/dist/app/browser/"
}

resource "aws_s3_bucket" "reactive_form" {
  bucket = var.bucket_name
}

# Separate website configuration
resource "aws_s3_bucket_website_configuration" "reactive_form_website" {
  bucket = aws_s3_bucket.reactive_form.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.reactive_form.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_public_block" {
  bucket = aws_s3_bucket.reactive_form.id

  block_public_acls   = true
  block_public_policy = false
  ignore_public_acls  = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.reactive_form.id

  policy = data.aws_iam_policy_document.allow_public_access.json
}

data "aws_iam_policy_document" "allow_public_access" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
    effect = "Allow"
  }
}

resource "aws_s3_object" "website_files" {
  for_each      = fileset(local.upload_directory, "**/*.*")
  bucket        = aws_s3_bucket.reactive_form.bucket
  key           = replace(each.value, local.upload_directory, "")
  source        = "${local.upload_directory}${each.value}"
  content_type  = lookup(var.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

output "website_domain" {
  value = aws_s3_bucket.reactive_form.website_domain
}

output "website_endpoint" {
  value = aws_s3_bucket.reactive_form.website_endpoint
}
