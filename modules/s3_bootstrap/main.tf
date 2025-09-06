# =============================================================================
# S3 BOOTSTRAP MODULE FOR VM-SERIES (PHASE 1 - BACKWARD COMPATIBLE)
# =============================================================================

# =============================================================================
# LOCALS FOR BACKWARD COMPATIBILITY
# =============================================================================

locals {
  # Convert old list format to new set format for backward compatibility
  config_files_final = length(var.config_files) > 0 ? var.config_files : toset(var.config)
  content_files_final = length(var.content_files) > 0 ? var.content_files : toset(var.content)
  license_files_final = length(var.license_files) > 0 ? var.license_files : toset(var.license)
  software_files_final = length(var.software_files) > 0 ? var.software_files : toset(var.software)
  other_files_final = length(var.other_files) > 0 ? var.other_files : toset(var.other)
}

# =============================================================================
# S3 BUCKET FOR BOOTSTRAP FILES
# =============================================================================

resource "aws_s3_bucket" "bootstrap" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = var.bucket_name
    Purpose     = "VM-Series Bootstrap"
    Environment = var.environment
    Project     = var.project_name
  }
}

# =============================================================================
# S3 BUCKET CONFIGURATION - SECURITY & COMPLIANCE
# =============================================================================

# Block all public access
resource "aws_s3_bucket_public_access_block" "bootstrap" {
  bucket = aws_s3_bucket.bootstrap.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "bootstrap" {
  bucket = aws_s3_bucket.bootstrap.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "bootstrap" {
  bucket = aws_s3_bucket.bootstrap.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# =============================================================================
# S3 OBJECTS - BOOTSTRAP FILE STRUCTURE
# =============================================================================

# Config files (bootstrap.xml, init-cfg.txt, etc.)
resource "aws_s3_object" "config_files" {
  for_each = local.config_files_final

  bucket = aws_s3_bucket.bootstrap.id
  key    = "config/${each.value}"
  source = "${var.file_location}${each.value}"

  # Generate ETag for change detection
  etag = filemd5("${var.file_location}${each.value}")

  tags = {
    Type        = "Config"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Content files 
resource "aws_s3_object" "content_files" {
  for_each = local.content_files_final

  bucket = aws_s3_bucket.bootstrap.id
  key    = "content/${each.value}"
  source = "${var.file_location}${each.value}"

  etag = filemd5("${var.file_location}${each.value}")

  tags = {
    Type        = "Content"
    Environment = var.environment
    Project     = var.project_name
  }
}

# License files
resource "aws_s3_object" "license_files" {
  for_each = local.license_files_final

  bucket = aws_s3_bucket.bootstrap.id
  key    = "license/${each.value}"
  source = "${var.file_location}${each.value}"

  etag = filemd5("${var.file_location}${each.value}")

  tags = {
    Type        = "License"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Software files
resource "aws_s3_object" "software_files" {
  for_each = local.software_files_final

  bucket = aws_s3_bucket.bootstrap.id
  key    = "software/${each.value}"
  source = "${var.file_location}${each.value}"

  etag = filemd5("${var.file_location}${each.value}")

  tags = {
    Type        = "Software"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Other/custom files
resource "aws_s3_object" "other_files" {
  for_each = local.other_files_final

  bucket = aws_s3_bucket.bootstrap.id
  key    = each.value
  source = "${var.file_location}${each.value}"

  etag = filemd5("${var.file_location}${each.value}")

  tags = {
    Type        = "Other"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create empty directory markers if no files provided
resource "aws_s3_object" "empty_directories" {
  for_each = toset([
    for dir in ["config", "content", "license", "software"] : dir
    if (
      (dir == "config" && length(local.config_files_final) == 0) ||
      (dir == "content" && length(local.content_files_final) == 0) ||
      (dir == "license" && length(local.license_files_final) == 0) ||
      (dir == "software" && length(local.software_files_final) == 0)
    )
  ])

  bucket  = aws_s3_bucket.bootstrap.id
  key     = "${each.value}/"
  content = ""

  tags = {
    Type        = "Directory"
    Environment = var.environment
    Project     = var.project_name
  }
}

# =============================================================================
# IAM ROLE AND INSTANCE PROFILE FOR VM-SERIES
# =============================================================================

# IAM role for VM-Series instances
resource "aws_iam_role" "vmseries" {
  count = var.create_instance_profile ? 1 : 0
  name  = "vmseries-bootstrap-role-${substr(sha256(var.bucket_name), 0, 8)}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "vmseries-bootstrap-role"
    Purpose     = "VM-Series Bootstrap"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM policy for S3 bootstrap access
resource "aws_iam_role_policy" "vmseries_bootstrap" {
  count = var.create_instance_profile ? 1 : 0
  name  = "vmseries-bootstrap-policy"
  role  = aws_iam_role.vmseries[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.bootstrap.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.bootstrap.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "vmseries" {
  count = var.create_instance_profile ? 1 : 0
  name  = "vmseries-bootstrap-profile-${substr(sha256(var.bucket_name), 0, 8)}"
  role  = aws_iam_role.vmseries[0].name

  tags = {
    Name        = "vmseries-bootstrap-profile"
    Purpose     = "VM-Series Bootstrap"
    Environment = var.environment
    Project     = var.project_name
  }
}