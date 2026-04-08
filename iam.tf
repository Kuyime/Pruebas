resource "aws_iam_role" "role_ec2" {
  name = "EC2RoleForCheckov"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_instance_profile" "profile_ec2" {
  name = "ec2_profile"
  role = aws_iam_role.role_ec2.name
}