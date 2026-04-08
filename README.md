# Terraform Demo

Este proyecto crea una red básica en AWS usando Terraform. Incluye una VPC con subredes públicas y privadas, un gateway de Internet, un NAT Gateway, rutas de tráfico para acceso público y privado, y una instancia EC2 con acceso SSH restringido.

## Alcance del proyecto

- Crear una VPC `10.0.0.0/16`
- Crear subredes públicas en `us-east-1a` y `us-east-1b`
- Crear subredes privadas en `us-east-1a` y `us-east-1b`
- Crear un Internet Gateway y asociarlo a la VPC
- Crear un NAT Gateway para conectar subredes privadas a Internet
- Configurar tablas de ruteo públicas y privadas
- Crear un grupo de seguridad que permita SSH desde una IP específica
- Crear una instancia EC2 en una subred pública

## Requisitos

- Terraform `1.14.8`
- Proveedor AWS `~> 6.39.0`
- Credenciales AWS configuradas localmente (por ejemplo, mediante `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` o el archivo `~/.aws/credentials`)

## Proveedor

- AWS
- Región configurada en `provider.tf`: `us-east-1`

## Estructura del proyecto

- `provider.tf` – Configuración de Terraform y proveedor AWS
- `vpc.tf` – Recursos de red: VPC, subredes, gateway, NAT y rutas
- `ec2.tf` – Grupo de seguridad SSH y la instancia EC2
- `terraform_name_check.rego` – Regla de validación de nombres Terraform
- `terraform_region_check.rego` – Regla de validación de región Terraform
- `install.sh` – Script de instalación/ayuda

## Uso

1. Inicializar Terraform:

```bash
terraform init
```

2. Revisar el plan:

```bash
terraform plan
```

3. Aplicar la infraestructura:

```bash
terraform apply
```

4. Eliminar la infraestructura:

```bash
terraform destroy
```

## Recursos creados

- VPC `mi_vpc`
- Internet Gateway `igw`
- Subred pública `subnet-publica-1`
- Subred pública `subnet-publica-2`
- Subred privada `subnet-privada-1`
- Subred privada `subnet-privada-2`
- Elastic IP `nat_eip`
- NAT Gateway `nat_gw`
- Tabla de ruteo pública `public_rt`
- Tabla de ruteo privada `private_rt`
- Asociaciones de tablas de ruteo públicas y privadas
- Grupo de seguridad `ssh-access`
- Instancia EC2 `mi_ec2`

## Notas importantes

- El grupo de seguridad SSH permite acceso solo desde la IP `201.189.206.99/32`.
- La instancia EC2 usa la AMI `ami-0fa8aad99729521be` y tipo `t2.micro`.
- No hay variables definidas en este proyecto; los valores están codificados en los archivos Terraform.
