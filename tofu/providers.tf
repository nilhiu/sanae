terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~>5.13"
    }
  }
}

provider "vault" {
  address = "http://127.0.0.1:8200"
}
