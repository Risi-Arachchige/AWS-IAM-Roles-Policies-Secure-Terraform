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
