#Declare Terraform Cloud backend
terraform {
  cloud {
    organization = "bm54cloud"

    workspaces {
      tags        = ["W22project"]
      description = "Workspace for Week 22 project"
    }
  }
}
