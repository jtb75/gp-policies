terraform {
  required_providers {
    wiz = {
      source  = "tf.app.wiz.io/wizsec/wiz"
      version = ">= 1.0"
    }
  }
}

# Authentication via environment variables:
#   WIZ_CLIENT_ID
#   WIZ_CLIENT_SECRET
provider "wiz" {}
