
variable "ami_name_prefix" {
  type    = string
  default = "ubuntu22.04-t4g"
}

# could not parse template for following block: "template: hcl2_upgrade:4: unterminated raw quoted string"

variable "aws_access_key" {
  type    = string
  default = "{{env `FILMFLIX_AWS_ACCESS_KEY}}"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

# could not parse template for following block: "template: hcl2_upgrade:4: unterminated raw quoted string"

variable "aws_secret_key" {
  type    = string
  default = "{{env `FILMFLIX_AWS_SECRET_KEY}}"
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

data "amazon-ami" "autogenerated_1" {
  access_key = "${var.aws_access_key}"
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-20230516"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "${var.aws_region}"
  secret_key  = "${var.aws_secret_key}"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "autogenerated_1" {
  access_key      = "${var.aws_access_key}"
  ami_description = "Ubuntu 22.04 ${var.machine_type} Host Image"
  ami_name        = "${var.machine_type}-packer-${local.timestamp}"
  instance_type   = "${var.instance_type}"
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = 7
    volume_type           = "gp3"
  }
  region = "${var.aws_region}"
  run_tags = {
    Name = "ff-${var.machine_type}-host"
    role = "ff-${var.machine_type}-host"
  }
  secret_key   = "${var.aws_secret_key}"
  source_ami   = "${data.amazon-ami.autogenerated_1.id}"
  ssh_username = "ubuntu"
  tags = {
    Name = "ff-${var.machine_type}-host"
    role = "ff-${var.machine_type}-host"
  }
}

build {
  sources = ["source.amazon-ebs.autogenerated_1"]

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
