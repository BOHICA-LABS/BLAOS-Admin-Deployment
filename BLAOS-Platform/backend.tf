data "terraform_remote_state" "platform" {
  backend = "local"

  config = {
    path = var.blaos_deployment_state_path
  }
}