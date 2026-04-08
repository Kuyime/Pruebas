# 1. Configuración de KMS
resource "aws_kms_key" "log_key" {
  description             = "Llave para cifrar logs de CloudWatch"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "log_key_alias" {
  name          = "alias/cloudwatch-logs-key-v3" # <-- Cambiado a v3
  target_key_id = aws_kms_key.log_key.key_id
}

resource "aws_kms_key_policy" "log_key_policy" {
  key_id = aws_kms_key.log_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow CloudWatch Logs"
        Effect    = "Allow"
        Principal = { Service = "logs.amazonaws.com" }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# 2. Infraestructura de Red (VPC, Subnets)
resource "aws_vpc" "mi_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Securizamos el Security Group por defecto de la VPC (NUEVO - Solución a CKV2_AWS_12)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.mi_vpc.id
}

# Internet Gateway (Requerido para el NAT)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mi_vpc.id

  tags = {
    Name = "igw-principal"
  }
}

# Subnets
resource "aws_subnet" "subnet_publica_1" {
  vpc_id                  = aws_vpc.mi_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "subnet_publica_2" {
  vpc_id                  = aws_vpc.mi_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "subnet_privada_1" {
  vpc_id                  = aws_vpc.mi_vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "subnet_privada_2" {
  vpc_id                  = aws_vpc.mi_vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false
}

# 3. Logging (CloudWatch y Flow Logs)
resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name              = "/aws/vpc/flow-logs-v4" # <-- Cambia de v3 a v4
  retention_in_days = 365
  kms_key_id        = aws_kms_key.log_key.arn
}
resource "aws_flow_log" "mi_flow_log" {
  iam_role_arn    = data.aws_iam_role.lab_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.mi_vpc.id
}

# 4. Otros Recursos (NAT Gateway, EIP)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet_publica_1.id

  depends_on = [aws_internet_gateway.igw]
}