# Nudge infrastructure

Minimal Terraform: a resource group, an AKS cluster (single small node pool),
and an Azure Container Registry the cluster can pull from. Postgres, the
backend, and the web app all run as containers *inside* the cluster — see
`/k8s` for those manifests.

## Prerequisites

- `terraform` >= 1.5
- `az login` with a subscription selected (`az account set --subscription <id>`)

## Usage

```bash
terraform init
terraform plan
terraform apply
```

All variables have defaults — nothing is required to get started. Override
`project_name` / `environment` / `location` / `node_count` / `node_vm_size`
via `-var` or a `terraform.tfvars` file if you want something other than a
single `Standard_B2s` node in `eastus`.

State is local (`terraform.tfstate`, gitignored) — fine for a single-operator
beta.

## After `apply`

```bash
terraform output
$(terraform output -raw get_credentials_command)   # points kubectl at the cluster
```

Then build and push images to the registry (`acr_login_server` output), and
apply the manifests in `/k8s` — see the root `README.md` / `/k8s` for the
full sequence.
