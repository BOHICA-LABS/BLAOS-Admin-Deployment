# Getting Started

## Create answers.tfvars

Rename the answers.tfvars.tpl to answers.tfvars and populate the varables. a description of each variable can be found inside the variables.tf file

### Variables Tables

| Variable                        | Type   | Description                                  | Example                  |
| ------------------------------- | ------ | -------------------------------------------- | ------------------------ |
| **rancher_hostname**            | String | The FQDN for the rancher instance            | "r.ad.example.com"       |
| **address_pool**                | String | The Address Pool to use for metalLB          | "192.168.35.248/24"      |
| **ca_common_name**              | String | The common name to use in the CA cert        | "ad.example.com"         |
| **organization_name**           | String | The orginization name to use in the CA cert  | "BOHICA LABS Cluster CA" |
| **blaos_deployment_state_path** | String | The datastore you want to use in the CA Cert | "C:\\terraform.tfstate"  |
| **k3s_config_path**             | String | The path to use for the k3s config path      | "C:\\k3s.yaml"           |

## Initialize terrafrom

```powershell
terraform.exe init
```

## View the build plan

```powershell
terraform.exe plan -var-file="answers.tfvars"
```

## Standup the Platform

```powershell
terraform.exe apply -var-file="answers.tfvars"
```

## Tear Down the Platform

```powershell
terraform.exe destroy -var-file="answers.tfvars"
```
