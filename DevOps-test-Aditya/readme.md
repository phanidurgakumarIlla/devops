
# Terraform Workshop: Deploy a Static Website on AWS S3 (Using AWS SSO)

## Workshop Objective
In this workshop, you will:
- Login to AWS using **IAM Identity Center (AWS SSO)**
- Use **Terraform** to deploy an **S3 static website**
- Upload `index.html` and `error.html`
- View the website in a browser
- Update the site and re-deploy
- Clean up all AWS resources at the end

---

## Information Provided by Instructor
You will receive the following from the instructor:

- **SSO Start URL**: <PROVIDED_BY_INSTRUCTOR>
- **SSO Region**: <PROVIDED_BY_INSTRUCTOR> (example: `ap-south-1`)
- **AWS Account**: <PROVIDED_BY_INSTRUCTOR>
- **Role / Permission Set**: `TerraformS3StaticWebsiteWorkshop`
- **Deployment Region**: <PROVIDED_BY_INSTRUCTOR>

> ⚠️ Important  
> Your S3 bucket **must start with `tfws-`**.  
> This is enforced by IAM permissions for safety.

---

## Prerequisites (Install Before Starting)

### 1. Install Terraform (v1.5+)
Download and install Terraform.

Verify:
```powershell
terraform -version
````

### 2. Install AWS CLI v2

Verify:

```powershell
aws --version
```

---

## Step 1: Configure AWS SSO

### 1.1 Configure SSO profile

Run:

```powershell
aws configure sso
```

Enter values:

* SSO start URL: <PROVIDED_BY_INSTRUCTOR>
* SSO region: <PROVIDED_BY_INSTRUCTOR>
* Select AWS account
* Select role: `TerraformS3StaticWebsiteWorkshop`
* Default region: ap-south-1
* Output format: `json`

### 1.2 Login

```powershell
aws sso login
```

### 1.3 Verify identity

```powershell
aws sts get-caller-identity
```

You should see an **assumed-role** ARN.

---

## Step 2: Create Project Folder

Create a folder:

```powershell
mkdir student-s3-website
cd student-s3-website
```

---

## Step 3: Create Terraform Files

### `versions.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}
```

### `provider.tf`

```hcl
provider "aws" {
  region = var.region
}
```

### `variables.tf`

```hcl
variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "student_id" {
  description = "Your name or initials (used in bucket name)"
  type        = string
}
```

### `main.tf`

```hcl
resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  bucket_name = "tfws-${var.student_id}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.site.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.site.id
  index_document { suffix = "index.html" }
  error_document { key = "error.html" }
}

data "aws_iam_policy_document" "public_read" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.public_read.json
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.site.id
  key          = "error.html"
  source       = "${path.module}/error.html"
  content_type = "text/html"
}
```

### `outputs.tf`

```hcl
output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.this.website_endpoint}"
}
```

---

## Step 4: Create Website Files

### `index.html`

Can be found in index.html

### `error.html`

```html
<!doctype html>
<html>
<head><meta charset="utf-8"><title>Error</title></head>
<body style="font-family:Arial;margin:40px;">
  <h2>Error Page</h2>
</body>
</html>
```

---

## Step 5: Terraform Initialize

```powershell
terraform init
```

---

## Step 6: Deploy the Website

Replace `YOURNAME` with your name or initials.

```powershell
terraform apply -var="student_id=YOURNAME"
```

Type `yes` when prompted.

---

## Step 7: Access the Website

Terraform will output:

* Bucket name
* Website URL

Open the URL in a browser.

> Note: S3 static website endpoints are **HTTP only**

---

## Step 8: Update and Re-Deploy

1. Edit `index.html` (add your name)
2. Save
3. Run:

```powershell
terraform apply -var="student_id=YOURNAME"
```

4. Refresh browser

---

## Step 9: Cleanup (MANDATORY)

```powershell
terraform destroy -var="student_id=YOURNAME"
```

Type `yes`.

---

## Troubleshooting

### Terraform init stuck or fails installing provider

Run:

```powershell
mkdir C:\tf-plugin-cache -Force
$env:TF_PLUGIN_CACHE_DIR="C:\tf-plugin-cache"
$env:TF_REGISTRY_CLIENT_TIMEOUT="300"
terraform init
```

If needed:

```powershell
Remove-Item -Recurse -Force .terraform -ErrorAction SilentlyContinue
Remove-Item -Force .terraform.lock.hcl -ErrorAction SilentlyContinue
terraform init
```

---

## Verification Commands

```powershell
aws sts get-caller-identity
aws s3 ls
```

---

## Commands Summary

```powershell
aws configure sso
aws sso login
aws sts get-caller-identity

terraform init
terraform apply -var="student_id=YOURNAME"
terraform destroy -var="student_id=YOURNAME"
```

---

## Notes

* Bucket prefix `tfws-` is required
* Always destroy resources at the end
* HTTPS requires CloudFront (not included in this lab)

---

🎉 **Congratulations! You deployed a static website on AWS using Terraform and SSO.**

```

---
