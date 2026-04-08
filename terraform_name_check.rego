package terraform.authz

import future.keywords.if

default allow = {
    "status": false,
    "reason": "El nombre de la instancia no es correcto."
}

allow = result if {
    some i
    resource := input.resource_changes[i]
    resource.type == "aws_instance"
    resource.change.after.tags.Name == "MY-EC2-Instance"

    result := {
        "status": true,
        "reason": "El nombre de la instancia es correcto."
    }
}