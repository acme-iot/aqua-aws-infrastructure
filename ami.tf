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


data "aws_ami" "mosquitto" {
  most_recent = true
  owners      = ["136963196437"]

  filter {
    name   = "name"
    values = ["Mosquitto*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
