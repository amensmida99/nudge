# Nudge infrastructure

Terraform: a VPC, an EKS cluster (single small managed node group), and two
ECR repositories the cluster can pull from. Postgres, the backend, and the
web app all run as containers *inside* the cluster — see `/k8s` for those
manifests.

## Prerequisites

- `terraform` >= 1.5
- AWS credentials configured (`aws configure`, or env vars / SSO profile)
  with an account/region selected

## Usage

```bash
terraform init
terraform plan
terraform apply
```

All variables have defaults — nothing is required to get started. Override
`project_name` / `environment` / `region` / `node_count` / `node_instance_type`
via `-var` or a `terraform.tfvars` file if you want something other than a
single `t3.small` node in `eu-central-1`.

State is local (`terraform.tfstate`, gitignored) — fine for a single-operator
beta.

## After `apply`

```bash
terraform output
$(terraform output -raw get_credentials_command)   # points kubectl at the cluster
```

Then build and push images to the registries (`ecr_backend_repository_url` /
`ecr_web_repository_url` outputs), and apply the manifests in `/k8s` — see
the root `README.md` / `/k8s` for the full sequence.

## Cost

Rough on-demand cost in `eu-central-1` with the defaults (1x `t3.small`
node, single NAT gateway):

| Resource            | Cost                              |
| -------------------- | ---------------------------------- |
| EKS control plane    | ~$73/mo (fixed, ~$0.10/hr)         |
| NAT gateway           | ~$32/mo + ~$0.045/GB processed     |
| 1x `t3.small` node    | ~$15/mo                            |

The control plane and NAT gateway bill hourly for as long as they exist —
there's no "stop" state for either of them, unlike an EC2 instance. Scaling
`node_count` to `0` only removes the node cost; the control plane and NAT
keep billing regardless.

**To actually stop paying between sessions**, tear the whole thing down and
recreate it when you need it again:

```bash
terraform destroy   # stops all billing
...
terraform apply     # ~15-20 min to recreate the cluster
```

Fine for a single-operator beta since state is local and nothing else
depends on the cluster staying up.
