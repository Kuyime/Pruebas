# Instrucciones del Laboratorio

Este documento explica paso a paso cómo trabajar con el proyecto Terraform y preparar el entorno de pruebas antes de automatizarlo con GitHub Actions.

## 1. Objetivo del laboratorio

El laboratorio propone crear un proyecto Terraform con los siguientes archivos:

- `provider.tf` — configuración de Terraform y del proveedor AWS
- `vpc.tf` — recursos de red: VPC, subredes, gateway, NAT, tablas de ruteo
- `ec2.tf` — grupo de seguridad SSH e instancia EC2

La idea es construir primero la infraestructura en Terraform y luego crear una instancia EC2 manualmente en AWS para tener un ambiente de prueba real. Después se instala `install.sh` para probar comandos e instalar herramientas, y finalmente se automatiza el flujo con GitHub Actions.

## 2. Crear el proyecto Terraform

1. Crear una carpeta para el proyecto y abrirla en tu editor.
2. Crear el archivo `provider.tf` con la configuración de Terraform y del proveedor AWS:

   - `required_version` para la versión de Terraform.
   - `required_providers` para usar `hashicorp/aws`.
   - El bloque `provider "aws"` con `region = "us-east-1"`.

3. Crear el archivo `vpc.tf` con los recursos de red:

   - `aws_vpc` para definir una red privada virtual.
   - `aws_internet_gateway` para dar salida a Internet desde la VPC.
   - `aws_subnet` públicas y privadas en diferentes zonas de disponibilidad.
   - `aws_eip` y `aws_nat_gateway` para que las subredes privadas tengan acceso a Internet.
   - `aws_route_table`, `aws_route_table_association` y `aws_route` para enrutar el tráfico público y privado.

4. Crear el archivo `ec2.tf` con la instancia EC2 y el grupo de seguridad:

   - `aws_security_group` que permita SSH únicamente desde una IP específica.
   - `aws_instance` con una AMI y tipo de instancia definidos, usando la subred pública y el grupo de seguridad.

## 3. Crear una instancia EC2 manualmente en AWS

Antes de ejecutar los comandos de Terraform en tu entorno local, primero crea una instancia EC2 manualmente para tener un ambiente de prueba real y poder ejecutar `install.sh` allí.

Pasos sugeridos:

1. Ir a la consola de EC2 en `us-east-1`.
2. Elegir la misma AMI que usarás en `ec2.tf`.
3. Seleccionar una instancia `t2.micro`.
4. Escoger la misma VPC creada por Terraform y una subred pública.
5. Asociar un par de claves o usar un método de acceso SSH compatible.
6. Verificar que el grupo de seguridad permita acceso SSH desde tu IP.

Este paso te permite tener un entorno real donde instalar y probar herramientas.

## 4. Instalar `install.sh` dentro de la EC2

Una vez creada la EC2 manualmente, conéctate a ella por SSH y copia el archivo `install.sh` desde tu repositorio o descárgalo directamente.

Pasos sugeridos:

```bash
chmod +x install.sh
./install.sh
```

El script realiza las siguientes acciones:

- Instala `pip3` si no está disponible.
- Instala `checkov` con `pip3`.
- Instala `terraform` desde el repositorio de HashiCorp.
- Instala `terraform-docs`.
- Instala `opa`.

Después de ejecutar `install.sh` en la EC2, tendrás un entorno de prueba con las herramientas necesarias para validar infraestructura y políticas.

## 5. Probar el proyecto Terraform

Una vez que la EC2 de prueba está lista y `install.sh` está instalado, regresa a tu máquina de desarrollo local y ejecuta los comandos Terraform para validar el proyecto.

1. Inicializar el proyecto:

   ```bash
   terraform init
   ```

2. Verificar y validar la configuración:

   ```bash
   terraform fmt -check -recursive
   terraform validate
   ```

3. Crear el plan:

   ```bash
   terraform plan -out=tfplan
   ```

4. Aplicar la infraestructura:

   ```bash
   terraform apply -auto-approve tfplan
   ```

5. Cuando termines, puedes destruir la infraestructura con:

   ```bash
   terraform destroy -auto-approve
   ```

## 6. Usar `install.sh` para preparar el entorno

El archivo `install.sh` instalara herramientas útiles para el laboratorio.

Pasos para ejecutar el script:

```bash
chmod +x install.sh
./install.sh
```

El script realiza las siguientes acciones:

- Instala `pip3` si no está disponible.
- Instala `checkov` con `pip3`.
- Instala `terraform` desde el repositorio de HashiCorp.
- Instala `terraform-docs`.
- Instala `opa`.

Una vez instalado, podrás usar `checkov`, `opa`, `terraform-docs` y otros comandos desde la terminal.

## 6. Explicación de las políticas OPA en `.rego`

El proyecto contiene dos reglas OPA:

### `terraform_name_check.rego`

- Esta política valida que el recurso `aws_instance` tenga un tag `Name` igual a `MY-EC2-Instance`.
- Si la instancia no cumple con ese tag, la política devuelve `status: false`.
- El objetivo es asegurar que las instancias se nombren de forma consistente y controlada.

### `terraform_region_check.rego`

- Esta política verifica que el proveedor AWS esté configurado en la región `us-east-1`.
- Si la región es distinta, la política genera un mensaje de error y devuelve `allow = false`.
- El propósito es forzar el despliegue en la región esperada y evitar errores de operación en otra región.

## 7. Exportar el plan en JSON

Para analizar el plan con herramientas como `tflint` y `checkov`, se debe exportar el plan a JSON.

1. Crear el plan con salida binaria:

   ```bash
   terraform plan -out=tfplan
   ```

2. Convertir el plan a JSON:

   ```bash
   terraform show -json tfplan > tfplan.json
   ```

3. Usar el JSON con las herramientas:

   - Con `checkov`:

     ```bash
     checkov -f tfplan.json
     ```

   - Con `tflint`:

     ```bash
     tflint --format json --out tflint-report.json
     ```

   Nota: `tflint` no consume directamente el JSON de Terraform plan, pero la estrategia de exportar el plan es útil para otros análisis y comparaciones.

## 8. Qué hace el pipeline en GitHub Actions

El pipeline de GitHub Actions automatiza la validación y despliegue de Terraform en cada `push` a `main` o `pull_request`.

Pasos del pipeline:

1. `Checkout`: descarga el código del repositorio.
2. `Configure AWS Credentials`: obtiene credenciales AWS desde los secretos de GitHub.
3. `Setup Python`: instala Python para ejecutar `pip`.
4. `Setup Terraform`: instala Terraform en el runner.
5. `Install Checkov`: instala la herramienta de análisis estático de infraestructura.
6. `Install OPA`: descarga e instala Open Policy Agent.
7. `Terraform Format Check`: verifica el formato con `terraform fmt`.
8. `Terraform Init`: inicializa el proyecto Terraform.
9. `Terraform Validate`: valida los archivos Terraform.
10. `Terraform Plan`: crea un plan de ejecución.
11. `Terraform Show JSON`: exporta el plan a `tfplan.json`.
12. `Checkov Static Analysis`: analiza el plan con `checkov`.
13. `OPA Policy Evaluation`: valida las políticas OPA sobre el plan.
14. `Terraform Apply`: aplica el plan a AWS.
15. `Upload Terraform State`: guarda el archivo `terraform.tfstate` como artefacto.

## 9. Cómo funciona el job de destroy

El pipeline agrega un job `destroy` separado con aprobación manual.

- El job `destroy` depende del job principal `terraform`.
- Usa un entorno protegido `destroy-approval` en GitHub.
- El paso `Terraform Destroy` elimina la infraestructura creada.

Esto permite que la destrucción se ejecute solo después de una confirmación explícita.

## 10. Configurar credenciales en GitHub

Para que el pipeline funcione, debes guardar las credenciales AWS en los secretos del repositorio:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` (opcional, solo si usas credenciales temporales)

También asegúrate de habilitar la protección del entorno `destroy-approval` si quieres un paso de confirmación manual antes de ejecutar `terraform destroy`.

## 11. Tips finales

- Usa `terraform fmt -recursive` regularmente para mantener el formato.
- Evita codificar valores sensibles directamente en los archivos Terraform.
- Revisa siempre el plan antes de aplicar cambios reales.
- Si necesitas cambiar la región, actualiza también la regla `terraform_region_check.rego`.
