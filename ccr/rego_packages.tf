resource "wiz_custom_rego_package" "jtb75_globals" {
  name = "JTB75 - Global Variables"
  content {
    rego {
      code = file("${path.module}/rego/packages/jtb75_globals.rego")
    }
  }
}
