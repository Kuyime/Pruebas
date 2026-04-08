package terraform.ssh

import rego.v1

default allow := false

allow if {
  not ssh_public_access
}

ssh_public_access if {
  sg := input.resource_changes[_]
  sg.type == "aws_security_group"
  ingress := sg.change.after.ingress[_]
  ingress.from_port == 22
  ingress.cidr_blocks[_] == "0.0.0.0/0"
}

violation contains msg if {
  sg := input.resource_changes[_]
  sg.type == "aws_security_group"
  ingress := sg.change.after.ingress[_]
  ingress.from_port == 22
  ingress.cidr_blocks[_] == "0.0.0.0/0"
  msg := sprintf("VIOLACION: Security Group '%v' expone SSH (Puerto 22) a 0.0.0.0/0.", [sg.address])
}