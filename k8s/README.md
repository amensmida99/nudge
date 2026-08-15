# Nudge Kubernetes manifests

Plain YAML (no Helm) for running Postgres, the backend, and the web app on
the EKS cluster provisioned by `/infra`. Everything lives in the `nudge`
namespace.

- `00-namespace.yaml` — the `nudge` namespace
- `01-postgres.yaml` — Postgres `StatefulSet` (1 replica, 1Gi PVC) + `Service`
- `02-backend.yaml` — backend `Deployment` + `LoadBalancer` `Service` (port 80 → 4000)
- `03-web.yaml` — web `Deployment` + `LoadBalancer` `Service` (port 80 → 3000)

## Prerequisites

- `/infra` applied (`terraform apply`) — gives you the EKS cluster and two ECR repos
- `kubectl`, pointed at the cluster:
  ```bash
  aws eks update-kubeconfig --region <region> --name <cluster_name>
  ```
  (both from `terraform output` in `/infra`)
- `docker`, logged into the registries:
  ```bash
  aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com
  ```

## 1. Build and push the images

```bash
BACKEND_REPO=<ecr_backend_repository_url>   # terraform output ecr_backend_repository_url
WEB_REPO=<ecr_web_repository_url>           # terraform output ecr_web_repository_url

docker build -t $BACKEND_REPO:latest ../backend
docker push $BACKEND_REPO:latest

# The web image needs to know the backend's URL at build time (see step 3 for
# why this is a two-pass process the first time you deploy).
docker build --build-arg NEXT_PUBLIC_API_BASE_URL=http://<backend-external-ip> \
  -t $WEB_REPO:latest ../web
docker push $WEB_REPO:latest
```

Then point the `image:` fields in `02-backend.yaml` and `03-web.yaml` at
these, e.g.:

```bash
sed -i '' "s|REPLACE_WITH_ECR_BACKEND_REPOSITORY_URL|$BACKEND_REPO|" 02-backend.yaml
sed -i '' "s|REPLACE_WITH_ECR_WEB_REPOSITORY_URL|$WEB_REPO|" 03-web.yaml
```

## 2. Create the secrets

Not committed to git — create them once per cluster:

```bash
kubectl create namespace nudge --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic postgres-credentials -n nudge \
  --from-literal=POSTGRES_USER=nudge \
  --from-literal=POSTGRES_PASSWORD="$(openssl rand -base64 24)" \
  --from-literal=POSTGRES_DB=nudge

kubectl create secret generic backend-secrets -n nudge \
  --from-literal=JWT_SECRET="$(openssl rand -base64 32)"
```

## 3. Apply

```bash
kubectl apply -f 00-namespace.yaml -f 01-postgres.yaml -f 02-backend.yaml -f 03-web.yaml
kubectl -n nudge get pods -w
```

The first time through, the web image needs the backend's URL baked in, but
the backend doesn't have an external IP until it's deployed. So: deploy
`01-postgres.yaml` + `02-backend.yaml` first, wait for its `LoadBalancer` IP
(`kubectl -n nudge get svc backend`), then build/push/apply the web image
with that IP as `NEXT_PUBLIC_API_BASE_URL`. After that, the IP is stable
across redeploys (as long as you don't delete the Service), so later web
rebuilds don't need this dance.

```bash
kubectl -n nudge get svc
# NAME      TYPE           EXTERNAL-IP                              PORT(S)
# backend   LoadBalancer   a1b2c3.us-east-1.elb.amazonaws.com       80:xxxxx/TCP
# web       LoadBalancer   d4e5f6.us-east-1.elb.amazonaws.com       80:xxxxx/TCP
```

Open the web `EXTERNAL-IP` in a browser.

## Notes

- No ingress controller, no TLS, no custom domain — two plain `LoadBalancer`
  Services, each provisioning their own AWS Network Load Balancer. Simplest
  thing that works for a beta; add an ingress + cert-manager later if you
  need HTTPS/a real domain.
- Postgres data lives on a PVC backed by an EBS volume — it survives pod
  restarts, but there's no backup job. Fine for beta, not for anything you'd
  be upset to lose.
- To redeploy after a code change: rebuild + push the image, then
  `kubectl -n nudge rollout restart deployment/backend` (or `web`).
