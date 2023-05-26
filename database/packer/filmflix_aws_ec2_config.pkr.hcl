packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.5"
      source = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "instance_type" {
  type    = string
  default = "t4g.small"
}

variable "machine_type" {
  type    = string
  default = "${env("MACHINE_TYPE")}"
}

variable "playbook" {
  type    = string
  default = "ansible/${env("MACHINE_TYPE")}.yml"
}

variable "provision_script" {
  type    = string
  default = "provision.sh"
}

data "amazon-ami" "ubuntu20_04-t4g" {
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-20230517"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "ubuntu20_04-t4g" {
  region = "${var.aws_region}"
  ami_description = "Ubuntu 20.04 ${var.machine_type} Host Image"
  ami_name        = "${var.machine_type}-packer-${local.timestamp}"
  instance_type   = "${var.instance_type}"
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = 30
    volume_type           = "gp3"
  }
  run_tags = {
    Name = "ff-${var.machine_type}-host"
    role = "ff-${var.machine_type}-host"
  }
  source_ami   = "${data.amazon-ami.ubuntu20_04-t4g.id}"
  ssh_username = "ubuntu"
  tags = {
    Name = "ff-${var.machine_type}-host"
    role = "ff-${var.machine_type}-host"
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu20_04-t4g"]

  provisioner "file" {
    destination = "/var/tmp/"
    source      = "ansible"
  }

  provisioner "file" {
    destination = "/var/tmp/ansible/roles"
    source      = "roles"
  }

  provisioner "file" {
    destination = "/tmp/${var.provision_script}"
    source      = "provision.sh"
  }

  provisioner "shell" {
    inline = ["chmod u+x /tmp/${var.provision_script}", "/tmp/${var.provision_script} ${var.playbook}"]
  }

}
