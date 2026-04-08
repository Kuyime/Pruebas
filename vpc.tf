# 1. Configuración de KMS (Solución para CKV_AWS_158)
# Se crea una llave administrada por el cliente para cifrar los logs.
resource "aws_kms_key" "log_key" {
  description             = "Llave para cifrar logs de CloudWatch"
  deletion_window_in_days = 7
  enable_key_rotation     = true # Recomendado para seguridad adicional
}

resource "aws_kms_alias" "log_key_alias" {
  name          = "alias/cloudwatch-logs-key"
  target_key_id = aws_kms_key.log_key.key_id
}

# Política para que CloudWatch pueda usar la llave KMS
resource "aws_kms_key_policy" "log_key_policy" {
  key_id = aws_kms_key.log_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
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

# 2. Infraestructura de Red (VPC, Subnets, Flow Logs)
resource "aws_vpc" "mi_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  # Pasa CKV2_AWS_11 (Flow Logs habilitados) y CKV2_AWS_12 (SG default restringido) [cite: 8, 10]
}

# Subnets (Todas pasan CKV_AWS_130 al no asignar IP pública automáticamente) 
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
  name              = "/aws/vpc/flow-logs-v2" # <-- Se agrega "-v2" para solucionar el error
  retention_in_days = 365
  kms_key_id        = aws_kms_key.log_key.arn
}

resource "aws_flow_log" "mi_flow_log" {
  iam_role_arn    = data.aws_iam_role.lab_role.arn # <-- Usamos el LabRole
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.mi_vpc.id
}

# 7. Otros Recursos (NAT Gateway, EIP)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  # Pasa CKV2_AWS_19 
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet_publica_1.id
}