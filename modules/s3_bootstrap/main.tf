
resource "aws_s3_bucket" "bootstrap" {
  bucket = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_acl" "bootstrap_acl" {
  bucket = aws_s3_bucket.bootstrap.id
  acl    = "private"
}

resource "aws_s3_object" "config_full" {
  count  = length(var.config) > 0 ? length(var.config) : "0"
  key    = "config/${element(var.config, count.index)}"
  source = "${var.file_location}${element(var.config, count.index)}"
  bucket = aws_s3_bucket.bootstrap.id
  acl    = "private"
}

resource "aws_s3_object" "content_full" {
  count  = length(var.content) > 0 ? length(var.content) : "0"
  key    = "content/${element(var.content, count.index)}"
  source = "${var.file_location}${element(var.content, count.index)}"
  bucket = aws_s3_bucket.bootstrap.id
  acl    = "private"
}

resource "aws_s3_object" "software_full" {
  count  = length(var.software) > 0 ? length(var.software) : "0"
  key    = "software/${element(var.software, count.index)}"
  source = "${var.file_location}${element(var.software, count.index)}"
  bucket = aws_s3_bucket.bootstrap.id
  acl    = "private"
}

resource "aws_s3_object" "license_full" {
  count  = length(var.license) > 0 ? length(var.license) : "0"
  key    = "license/${element(var.license, count.index)}"
  source = "${var.file_location}${element(var.license, count.index)}"
  bucket = aws_s3_bucket.bootstrap.id
  acl    = "private"
}

resource "aws_s3_object" "other_full" {
  count  = length(var.other) > 0 ? length(var.other) : "0"
  key    = element(var.other, count.index)
  source = "${var.file_location}${element(var.other, count.index)}"
  bucket = aws_s3_bucket.bootstrap.id
  acl    = "private"
}

resource "aws_s3_object" "config_empty" {
  count   = length(var.config) == 0 ? 1 : 0
  key     = "config/"
  content = "config/"
  bucket  = aws_s3_bucket.bootstrap.id
  acl     = "private"
}

resource "aws_s3_object" "content_empty" {
  count   = length(var.content) == 0 ? 1 : 0
  key     = "content/"
  content = "content/"
  bucket  = aws_s3_bucket.bootstrap.id
  acl     = "private"
}

resource "aws_s3_object" "license_empty" {
  count   = length(var.license) == 0 ? 1 : 0
  key     = "license/"
  content = "license/"
  bucket  = aws_s3_bucket.bootstrap.id
  acl     = "private"
}

resource "aws_s3_object" "software_empty" {
  count   = length(var.software) == 0 ? 1 : 0
  key     = "software/"
  content = "software/"
  bucket  = aws_s3_bucket.bootstrap.id
  acl     = "private"
}





resource "random_string" "main" {
  length      = 15
  min_lower   = 10
  min_numeric = 5
  special     = false
}

resource "aws_iam_role" "main" {
  count   = var.create_instance_profile ? 1 : 0
  name = "vmseries-iam-role-${random_string.main.result}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
      "Service": "ec2.amazonaws.com"
    },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "main" {
  count = var.create_instance_profile ? 1 : 0
  name = "vmseries-iam-policy-${random_string.main.result}"
  role = aws_iam_role.main.0.id

  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bootstrap.id}"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bootstrap.id}/*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bootstrap.id}"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bootstrap.id}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": [
          "*"
      ]
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "main" {
  count = var.create_instance_profile ? 1 : 0
  name = "vmseries-instance-profile-${random_string.main.result}"
  role = aws_iam_role.main.0.name
  path = "/"
}
