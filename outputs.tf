output "ip" {
  description = "The IP address where the JupyterHub single-user instance was launched"
  value = "${local.jupyter_ip}"
}
output "port" {
  description = "The listening port of the launched JupyterHub single-user instance"
  value = "${local.jupyter_port}"
}
output "state" {
  description = "The JupyterHub single-user running state, an empty string if it is, an exit status (0 if unknown) if it is not."
  value = "${local.jupyter_state}"
}
