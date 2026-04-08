package terraform.ec2

import rego.v1

default allow_instance_type := false

allow_instance_type if {
  not invalid_instance_type
}

invalid_instance_type if {
  ec2 := input.resource_changes[_]
  ec2.type == "aws_instance"
  ec2.change.after.instance_type != "t2.micro"
}

violation contains msg if {
  ec2 := input.resource_changes[_]
  ec2.type == "aws_instance"
  ec2.change.after.instance_type != "t2.micro"
  msg := sprintf("VIOLACION: Instancia EC2 '%v' usa tipo '%v'. Solo se permite 't2.micro'.", [ec2.address, ec2.change.after.instance_type])
}