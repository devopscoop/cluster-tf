module "bootstrap" {
  source  = "trussworks/bootstrap/aws"
  version = "v5.2.0"

  account_alias = var.account_alias
  region        = var.region
}
