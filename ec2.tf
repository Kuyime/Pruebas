resource "aws_security_group" "ssh_access" {
  name        = "ssh-access"
  description = "Permitir acceso SSH restringido"
  vpc_id      = aws_vpc.mi_vpc.id

  ingress {
    description = "SSH desde mi IP segura"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["201.189.206.99/32"] # SOLUCIÓN CKV_AWS_24
  }

  egress {
    description = "Salida restringida HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SOLUCIÓN CKV_AWS_382
  }

  tags = { Name = "ssh-access" }
}

resource "aws_instance" "mi_ec2" {
  ami                    = "ami-0fa8aad99729521be"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet_publica_1.id
  vpc_security_group_ids = [aws_security_group.ssh_access.id]

  monitoring    = true # SOLUCIÓN CKV_AWS_126
  ebs_optimized = true # SOLUCIÓN CKV_AWS_135

  # --- LA PIEZA QUE FALTA ---
  iam_instance_profile = aws_iam_instance_profile.profile_ec2.name # SOLUCIÓN CKV2_AWS_41

  metadata_options {
    http_tokens = "required" # SOLUCIÓN CKV_AWS_79
  }

  root_block_device {
    encrypted = true # SOLUCIÓN CKV_AWS_8
  }

  tags = { Name = "MY-EC2-Instance" }
}