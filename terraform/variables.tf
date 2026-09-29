variable "aws_profile" {
  description = "AWS profile"
  type        = string
  default     = null
}
variable "bucket_name" {
  description = "AWS bucket"
  type        = string
}
variable "backup_prefix" {
  description = "AWS prefix"
  type        = string
  default     = "laptop"
}
variable "retention_days" {
  description = "AWS retention days"
  type        = number
  default     = 30
  validation {
    condition     = var.retention_days > 0
    error_message = "retention_days must be greater than 0."
  }
}
variable "iam_user_name" {
  description = "AWS iam user name"
  type        = string
  default     = "smart-backup-uploader"
}
variable "aws_region" {
  description = "AWS region for the backup bucket"
  type        = string
  default     = "eu-central-1"
}