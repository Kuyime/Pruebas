package terraform_region_check

import future.keywords.if

# Por defecto, NO permitimos nada (esto es más seguro)
default allow = false

# Definimos cuándo SÍ está permitido
allow if {
    # Buscamos la configuración del provider de AWS
    region := input.configuration.provider_config.aws.expressions.region.constant_value
    region == "us-east-1"
}

# Si quieres mantener los mensajes de error para el log:
deny[msg] if {
    region := input.configuration.provider_config.aws.expressions.region.constant_value
    region != "us-east-1"
    msg := sprintf("Error: Se intentó usar la región %v, pero solo se permite us-east-1", [region])
}