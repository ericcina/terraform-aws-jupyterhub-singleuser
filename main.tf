data "aws_ami" "chosen-image" {
  most_recent = true

  filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
}

//
// Convert map(k,v) to string list [k1='v1',...,kn='vn']
locals {
  env_override = {
    PATH = "/bin:/usr/bin:/sbin:/usr/sbin",
  }
  merged_env = "${merge(var.env, local.env_override)}"
  env_keys = "${keys(local.merged_env)}"
}
data "template_file" "environment" {
  count = "${length(local.env_keys)}"
  template = "$${key}=\"$${value}\""
  vars = {
    key = "${local.env_keys[count.index]}"
    value = "${lookup(local.merged_env, local.env_keys[count.index])}"
  }
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/templates/cloud-init.yaml")}"
  vars = {
    ip = "0.0.0.0"
    port = "${local.jupyter_port}"
    environment_b64 = "${base64encode(join("\n",data.template_file.environment.*.rendered))}"

    user = "${local.merged_env["JUPYTERHUB_USER"]}"
  }
}

resource "aws_instance" "slave-server" {
  ami           = "${data.aws_ami.chosen-image.id}"
  instance_type = "${var.instance_type}"
  key_name = "mykey"
  security_groups = ["${aws_security_group.web-proxies.name}"]
  tags = {
    "Name" = "${local.merged_env["JUPYTERHUB_USER"]}-jhub-singleuser"
  }

  user_data = <<YAML
#!/bin/bash
# Install conda
${local.sudo_prefix} wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
${local.sudo_prefix} bash miniconda.sh -b -p $HOME/miniconda
${local.sudo_prefix} export PATH="$HOME/miniconda/bin:$PATH"
# Create environment
${local.sudo_prefix} conda create -n nb notebook
${local.sudo_prefix} conda activate nb
${local.sudo_prefix} jupyter notebook
YAML
}
