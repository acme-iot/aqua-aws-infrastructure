data "aws_ami" "hivemq" {
  most_recent = true
  owners      = ["474125479812"]

  filter {
    name   = "name"
    values = ["HiveMQ 4.3.*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
