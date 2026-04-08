# Referenciamos el rol preexistente del entorno de laboratorio
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Creamos el perfil de instancia referenciando directamente al LabRole
resource "aws_iam_instance_profile" "profile_ec2" {
  name = "ec2_profile_v2" # <-- Actualizado para evitar el error EntityAlreadyExists
  role = data.aws_iam_role.lab_role.name
}