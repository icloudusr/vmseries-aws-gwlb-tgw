# =============================================================================
# S3 BOOTSTRAP MODULE - OUTPUTS (PHASE 1 - SIMPLIFIED)
# =============================================================================

output "bucket_name" {
  description = "Name of the created S3 bootstrap bucket"
  value       = aws_s3_bucket.bootstrap.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bootstrap bucket"
  value       = aws_s3_bucket.bootstrap.arn
}

# =============================================================================
# IAM OUTPUTS
# =============================================================================

output "instance_profile" {
  description = "Name of the IAM instance profile for VM-Series (null if not created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.vmseries[0].name : null
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile for VM-Series (null if not created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.vmseries[0].arn : null
}

output "iam_role_name" {
  description = "Name of the IAM role for VM-Series (null if not created)"
  value       = var.create_instance_profile ? aws_iam_role.vmseries[0].name : null
}

output "iam_role_arn" {
  description = "ARN of the IAM role for VM-Series (null if not created)"
  value       = var.create_instance_profile ? aws_iam_role.vmseries[0].arn : null
}

# =============================================================================
# BOOTSTRAP INSTRUCTIONS
# =============================================================================

output "bootstrap_instructions" {
  description = "Instructions for using this bootstrap bucket with VM-Series"
  value = {
    user_data_example = "vmseries-bootstrap-aws-s3bucket=${aws_s3_bucket.bootstrap.id}"
    required_iam_role = var.create_instance_profile ? aws_iam_instance_profile.vmseries[0].name : "Create instance profile separately"
  }
}