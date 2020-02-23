provider "aws" {
  region = var.region
}

locals {

    hive_ami = data.aws_ami.hivemq.id

}