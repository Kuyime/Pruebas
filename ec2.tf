resource "aws_security_group" "ssh_access" {
  name        = "ssh-access"
  description = "Permitir acceso SSH restringido"
  vpc_id      = aws_vpc.mi_vpc.id

  ingress {
    description = "SSH desde mi IP segura"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["201.189.206.99/32"] # CKV_AWS_24 [cite: 22]
  }

  egress {
    description = "Salida restringida HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # CKV_AWS_382 [cite: 24]
  }

  tags = { Name = "ssh-access" }
}

resource "aws_instance" "mi_ec2" {
  ami                    = "ami-0fa8aad99729521be"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet_publica_1.id
  vpc_security_group_ids = [aws_security_group.ssh_access.id]

  monitoring           = true                                      # CKV_AWS_126 [cite: 17]
  ebs_optimized        = true                                      # CKV_AWS_135 [cite: 15]
  iam_instance_profile = aws_iam_instance_profile.profile_ec2.name # CKV2_AWS_41 [cite: 24]

  metadata_options {
    http_tokens = "required" # CKV_AWS_79 [cite: 21]
  }

  root_block_device {
    encrypted = true # CKV_AWS_8 
  }

  tags = { Name = "MY-EC2-Instance" }
}