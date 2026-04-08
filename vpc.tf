# 1. Configuración de KMS (Aprobado para CKV_AWS_158)
resource "aws_kms_key" "log_key" {
  description             = "Llave para cifrar logs de CloudWatch" [cite: 17]
  deletion_window_in_days = 7 [cite: 17]
  enable_key_rotation     = true # Pasa CKV_AWS_7 [cite: 17]
}

resource "aws_kms_alias" "log_key_alias" {
  name          = "alias/cloudwatch-logs-key" [cite: 17]
  target_key_id = aws_kms_key.log_key.key_id [cite: 17]
}

# Política de la llave KMS para CloudWatch
resource "aws_kms_key_policy" "log_key_policy" {
  key_id = aws_kms_key.log_key.id [cite: 17]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions" [cite: 18]
        Effect = "Allow" [cite: 18]
        Principal = { AWS = "*" } [cite: 18]
        Action   = "kms:*" [cite: 18]
        Resource = "*" [cite: 18]
      },
      {
        Sid    = "Allow CloudWatch Logs" [cite: 19]
        Effect = "Allow" [cite: 19]
        Principal = { Service = "logs.amazonaws.com" } [cite: 19]
        Action = [
          "kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:Describe*" [cite: 19, 20]
        ]
        Resource = "*" 
      }
    ]
  })
}

# 2. Infraestructura de Red
resource "aws_vpc" "mi_vpc" {
  cidr_block           = "10.0.0.0/16" 
  enable_dns_hostnames = true 
  enable_dns_support   = true 
}

# --- SOLUCIÓN PARA CKV2_AWS_12 ---
# Este bloque toma el SG que AWS crea por defecto y le quita todas las reglas.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.mi_vpc.id
}

# Subnets (Pasan CKV_AWS_130)
resource "aws_subnet" "subnet_publica_1" {
  vpc_id                  = aws_vpc.mi_vpc.id [cite: 21]
  cidr_block              = "10.0.1.0/24" [cite: 21]
  map_public_ip_on_launch = false [cite: 21]
}

resource "aws_subnet" "subnet_publica_2" {
  vpc_id                  = aws_vpc.mi_vpc.id [cite: 21]
  cidr_block              = "10.0.2.0/24" [cite: 21]
  map_public_ip_on_launch = false [cite: 21]
}

resource "aws_subnet" "subnet_privada_1" {
  vpc_id                  = aws_vpc.mi_vpc.id [cite: 22]
  cidr_block              = "10.0.3.0/24" [cite: 22]
  map_public_ip_on_launch = false [cite: 22]
}

resource "aws_subnet" "subnet_privada_2" {
  vpc_id                  = aws_vpc.mi_vpc.id [cite: 22]
  cidr_block              = "10.0.4.0/24" [cite: 22]
  map_public_ip_on_launch = false [cite: 22]
}

# 3. Logging (Aprobado para CKV_AWS_158, 338 y 66)
resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name              = "/aws/vpc/flow-logs-v2" [cite: 23]
  retention_in_days = 365 [cite: 23]
  kms_key_id        = aws_kms_key.log_key.arn [cite: 23]
}

resource "aws_flow_log" "mi_flow_log" {
  iam_role_arn    = data.aws_iam_role.lab_role.arn [cite: 23]
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn [cite: 23]
  traffic_type    = "ALL" [cite: 23]
  vpc_id          = aws_vpc.mi_vpc.id [cite: 23]
}

# 4. Otros Recursos
resource "aws_eip" "nat_eip" {
  domain = "vpc" [cite: 24]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id [cite: 24]
  subnet_id     = aws_subnet.subnet_publica_1.id [cite: 24]
}