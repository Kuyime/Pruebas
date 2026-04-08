# Rol para Flow Logs
resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

# Política para Flow Logs (SOLUCIÓN CKV_AWS_355 y CKV_AWS_290) [cite: 25]
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.flow_log_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect = "Allow"
      # Restringimos el acceso solo a nuestro grupo de logs específico
      Resource = "${aws_cloudwatch_log_group.vpc_log_group.arn}:*"
    }]
  })
}

# Rol e Instancia Profile para la EC2 (CKV2_AWS_41) [cite: 24]
resource "aws_iam_role" "role_ec2" {
  name = "EC2RoleForCheckov"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "profile_ec2" {
  name = "ec2_profile"
  role = aws_iam_role.role_ec2.name
}