# How to Setup a Secure AWS IAM User and Role with Terraform

This Terraform project demonstrates the configuration of AWS IAM resources to provide secure, limited-access permissions for a user and a role within AWS. The configuration includes an IAM user with read-only permissions to EC2, secured access keys, multi-factor authentication (MFA), and a role for trusted access by EC2 instances.

## Table of Contents

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Configuration Details](#configuration-details)
- [Step-by-Step Setup Guide](#step-by-step-setup-guide)
- [Policy Files](#policy-files)
- [Outputs](#outputs)
- [Security Best Practices](#security-best-practices)
- [Conclusion](#conclusion)

## Project Overview

This project creates the following AWS resources:
- **IAM User**: A user named "kevin" with EC2 read-only access.
- **IAM Policy**: A policy that grants read-only permissions to EC2 and associated services.
- **IAM Role**: A role with trusted access for EC2 services, allowing them to assume this role with limited permissions.
- **Access Key and MFA**: Programmatic access keys for secure access, protected by MFA.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) installed on your machine (version 1.0 or higher recommended).
- An [AWS account](https://aws.amazon.com/) with IAM permissions to create users, roles, and policies.
- [GPG](https://gnupg.org/download/) installed for encryption key management.

## Project Structure

aws-iam-terraform/ ├── main.tf # Main Terraform configuration file ├── ec2-read-only-policy.json # JSON file defining the EC2 read-only policy ├── trust-role-policy.json # JSON file defining the role trust policy ├── kevin_pub_key.asc # Public GPG key for secure password management └── README.md # Documentation file


## Configuration Details

- **Provider**: Sets the AWS provider region to `us-east-2`.
- **IAM User**: Creates a user named "kevin" with limited privileges.
- **IAM Policy**: Attaches a custom EC2 read-only policy to the user.
- **IAM Access Key**: Generates secure programmatic access keys.
- **MFA and Encryption**: Protects sensitive data with MFA and GPG encryption.
- **IAM Role**: Creates a role that EC2 instances can assume, with the same limited access to EC2 resources.

## Step-by-Step Setup Guide

## 1. Configure the AWS Provider


Set the AWS provider region. Here, `us-east-2` is specified.
```
provider "aws" {
  region = "us-east-2"
}
```
## 2. Create the IAM User with Minimal Privileges

This block creates an IAM user named "kevin" and ensures it is deleted automatically if Terraform is run with destroy.
```
resource "aws_iam_user" "test_user" {
  name          = "kevin"
  force_destroy = true
}
```

## 3. Attach a Secure EC2 Read-Only Policy to the IAM User

Define and attach a custom policy with read-only access to EC2. The policy is defined in ec2-read-only-policy.json.
```
resource "aws_iam_policy" "ec2_readonly" {
  name        = "Ec2ReadOnlyPolicy"
  description = "Read only access to EC2"
  policy      = file("ec2-read-only-policy.json")
}

resource "aws_iam_user_policy_attachment" "user_policy_attach" {
  user       = aws_iam_user.test_user.name
  policy_arn = aws_iam_policy.ec2_readonly.arn
}
```

## 4. Create IAM Access Key

Generate an access key for "kevin" to allow programmatic access to AWS.
```
resource "aws_iam_access_key" "test_user_user_key" {
  user = aws_iam_user.test_user.name
}
```

## 5. Enable Multi-Factor Authentication (MFA) with Encryption

This step sets up a secure login profile for "kevin" using a GPG key to encrypt sensitive login information. Replace "kevin_pub_key.asc" with your actual public GPG key file.
```
resource "aws_iam_user_login_profile" "secure_user_login" {
  user    = aws_iam_user.test_user.name
  pgp_key = file("kevin_pub_key.asc")
}
```

## 6. Set Up an IAM Role with Trusted Access for EC2

The role, defined by trust-role-policy.json, allows EC2 instances to assume this role and access EC2 read-only services.
```
resource "aws_iam_role" "app_role" {
  name               = "app-role"
  assume_role_policy = file("trust-role-policy.json")
}

resource "aws_iam_role_policy_attachment" "app_role_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.ec2_readonly.arn
}
```

# Policy Files
## trust-role-policy.json

Defines the trust relationship for the role, allowing EC2 instances to assume this role.
```
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
```

## ec2-read-only-policy.json

Specifies the actions allowed on EC2 and related services, restricting the role to read-only permissions.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:Describe*",
            "Resource": "*"
        }
    ]
}
```

# Outputs

These outputs are generated upon successful Terraform execution. They contain sensitive information for accessing AWS programmatically.
```
output "user_access_key" {
  value     = aws_iam_access_key.test_user_user_key.id
  sensitive = true
}

output "user_secret_key" {
  value     = aws_iam_access_key.test_user_user_key.secret
  sensitive = true
}
```

# Security Best Practices

    GPG Encryption: Protect sensitive data by encrypting it using GPG.
    MFA: Secure access by enforcing Multi-Factor Authentication.
    Least Privilege: Use read-only permissions to limit access to necessary actions.
    Policy Attachments: Use aws_iam_user_policy_attachment for granular access control, avoiding conflicts in policy management.


# Conclusion

This project demonstrates the setup of secure IAM users and roles in AWS using Terraform. By following these configurations, you can manage access securely while ensuring resources are accessible only with necessary permissions.

# Finished Configuration (main.tf)

```
# Configure the provider and Region
provider "aws" {
  region = "us-east-2"
}

# Create the IAM user with minimal privileges
resource "aws_iam_user" "test_user" {
  name          = "kevin"
  force_destroy = true

}

# Attach a secure policy for limited access

resource "aws_iam_policy" "ec2_readonly" {
  name        = "Ec2ReadOnlyPolicy"
  description = "Read only access to EC2"
  policy      = file("ec2-read-only-policy.json") # Create ec2-read-only-policy.json file in the current directory with read-only permissions.

}

# using aws_iam_policy_attachment can lead to unexpected issues because it enforces exclusive 
# attachment of an IAM policy across the entire account, potentially disrupting other policies. 
# Instead, to avoid policy conflicts, using aws_iam_role_policy_attachment, aws_iam_user_policy_attachment, 
# or aws_iam_group_policy_attachment is a safer choice, as they provide more granular control without enforcing exclusivity.

resource "aws_iam_user_policy_attachment" "user_policy_attach" {
  user       = aws_iam_user.test_user.name
  policy_arn = aws_iam_policy.ec2_readonly.arn
}

# Create IAM access key

resource "aws_iam_access_key" "test_user_user_key" {
  user = aws_iam_user.test_user.name
}

# Enable Multi-factor authenticationcheck

resource "aws_iam_user_login_profile" "secure_user_login" {
  user    = aws_iam_user.test_user.name
  pgp_key = file("kevin_pub_key.asc")

  # Replace above with your PGP key.

}

# Setup an IAM role with trusted access

resource "aws_iam_role" "app_role" {
  name               = "app-role"
  assume_role_policy = file("trust-role-policy.json")
}

resource "aws_iam_role_policy_attachment" "app_role_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.ec2_readonly.arn
}

# Output credentials

output "user_access_key" {
  value     = aws_iam_access_key.test_user_user_key.id
  sensitive = true
}

output "user_secret_key" {
  value     = aws_iam_access_key.test_user_user_key.secret
  sensitive = true
}
```