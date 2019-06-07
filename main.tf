provider "aws" {region = "us-west-2"}

variable "vpc_id" {
}

variable "ssh_keypair" {
}

variable "base_name" {
}


resource "aws_security_group" "k3s-arm" {
  name        = "k3s-arm-${var.base_name}"
  description = "k3s-arm-${var.base_name}"
  vpc_id      = "${var.vpc_id}"
  }

resource "aws_security_group_rule" "ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "TCP"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.k3s-arm.id}"
}
resource "aws_security_group_rule" "outbound_allow_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.k3s-arm.id}"
}

resource "aws_security_group_rule" "kubeapi" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "TCP"
  self            = true  
  security_group_id = "${aws_security_group.k3s-arm.id}"

}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
  }

resource "aws_instance" "server" {
  ami           = "ami-0dc34f4b016c9ce49"
  instance_type = "a1.large"
  user_data = "${file("cloud-config-server.yml")}"
  key_name = "${var.ssh_keypair}"
  vpc_security_group_ids = ["${aws_security_group.k3s-arm.id}"]
  tags = {
    Name = "${var.base_name}-arm-k3s-server"
  }
}

resource "aws_instance" "worker" {
  ami           = "ami-0dc34f4b016c9ce49"
  instance_type = "a1.large"
  user_data = "${file("cloud-config-worker.yml")}"
  key_name = "${var.ssh_keypair}"
  vpc_security_group_ids = ["${aws_security_group.k3s-arm.id}"]
  tags = {
    Name = "${var.base_name}-arm-k3s-worker"
  }
}
