output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "versioning_enabled" {
  description = "Whether versioning is enabled for the bucket"
  value       = length(aws_s3_bucket_versioning.this) > 0 ? true : false
}