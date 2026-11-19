terraform {
  before_hook "pf_vault_up" {
    commands = ["apply", "plan", "destroy", "console", "refresh", "import"]
    execute  = ["${get_terragrunt_dir()}/scripts/pf-vault.sh", "up"]
  }

  after_hook "pf_vault_down" {
    commands     = ["apply", "plan", "destroy", "console", "refresh", "import"]
    execute      = ["${get_terragrunt_dir()}/scripts/pf-vault.sh", "down"]
    run_on_error = true
  }
}
