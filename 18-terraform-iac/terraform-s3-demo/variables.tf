variable "aws_region" {
  description = "AWS region where the bucket will be created"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique, lowercase, no underscores)"
  type        = string
}

variable "environment" {
  description = "Environment tag for the bucket"
  type        = string
  default     = "dev"
}
