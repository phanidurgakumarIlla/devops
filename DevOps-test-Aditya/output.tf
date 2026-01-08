output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.this.website_endpoint}"
}
