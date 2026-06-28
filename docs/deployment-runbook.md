# ResolveOps & QuickHaul Deployment & Troubleshooting Runbook

This document details the step-by-step commands required to configure the administrative Jumpbox VM, connect to the private AKS cluster, bootstrap resources, deploy the application workloads, and troubleshoot common infrastructure issues.

---

## Phase 1: Jumpbox CLI Tool Setup
*Purpose: Install all required CLI utilities on the Ubuntu 22.04 Jumpbox VM.*

### 1. Install Azure CLI (`az`)
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install -y azure-cli
```

### 2. Install Kubernetes CLI (`kubectl`)
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

### 3. Install Helm
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh
helm version
```

---

## Phase 2: Establish Cluster Connectivity
*Purpose: Authenticate with Azure Active Directory and download the Kubernetes credentials.*

```bash
# 1. Log in to your Azure account
az login

# 2. Fetch the credentials for the private cluster
az aks get-credentials --resource-group sathvik-rg --name resolveops-aks-05 --overwrite-existing

# 3. Verify that the nodes are reachable
kubectl get nodes -o wide
```

---

## Phase 3: Bootstrap Kubernetes Namespaces & Secrets
*Purpose: Create isolation boundaries and configure environment secrets.*

```bash
# 1. Create target namespaces
kubectl create namespace resolveops-ai
kubectl create namespace quickhaul-dev
kubectl create namespace quickhaul-prod
kubectl create namespace argocd

# 2. Retrieve PostgreSQL Connection String from Key Vault
DB_URL=$(az keyvault secret show --vault-name sathvik-kv-07 --name database-url --query value -o tsv)

# 3. Create the Database Secret inside the cluster namespace
kubectl create secret generic resolveops-secrets \
  --from-literal=database-url="$DB_URL" \
  -n resolveops-ai
```

---

## Phase 4: Configure Workload Identity
*Purpose: Allow ResolveOps AI pods to leverage Azure AD Federated Credentials.*

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: resolveops-workload-identity-sa
  namespace: resolveops-ai
  annotations:
    azure.workload.identity/client-id: "9e044ec7-58af-469e-a596-0550209c4e48"
EOF
```

---

## Phase 5: Formatting Application Pods for User Node Pool
*Purpose: Ensure all workload deployments target the userpool.*

Add the `nodeSelector` block under `spec.template.spec` in your deployment manifests:

```yaml
spec:
  template:
    spec:
      serviceAccountName: resolveops-workload-identity-sa
      nodeSelector:
        kubernetes.azure.com/mode: user
```

---

## Phase 6: Deploy Argo CD & QuickHaul Workloads
*Purpose: Set up Argo CD in the cluster and establish GitOps CD pipelines.*

```bash
# 1. Add and update Argo CD repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 2. Install Argo CD
helm install argocd argo/argo-cd -n argocd

# 3. Fetch the auto-generated Argo CD Admin Password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# 4. Create the Argo CD Application Manifest (specifying registry parameters)
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: quickhaul-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/Resolveops-AI/resolveops-application.git'
    targetRevision: HEAD
    path: quickhaul/helm/quickhaul
    helm:
      valueFiles:
        - values-dev.yaml
      parameters:
        - name: global.imageRegistry
          value: resolveopsacr05.azurecr.io
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: quickhaul-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

---

## Phase 7: Configure Application Ingress (AGIC Routing)
*Purpose: Expose services publicly using Application Gateway.*

### 1. Create Ingress for Argo CD Portal
```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/backend-protocol: "http"
spec:
  rules:
  - host: argocd.sathvikdevops.site
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF
```

### 2. Configure Ingress for QuickHaul Application
```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: quickhaul-ingress
  namespace: quickhaul-dev
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - host: quickhaul.sathvikdevops.site
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: quickhaul-frontend
            port:
              number: 80
EOF
```

---

## Phase 8: Troubleshooting Log & Incident Resolution

### Incident 1: Kubernetes API Access Forbidden
* **Symptom:** `Error from server (Forbidden): nodes is forbidden` when running `kubectl get nodes`.
* **Cause:** Azure RBAC was enabled for the AKS API, but the active user was not assigned administrative roles.
* **Resolution:** Added role assignments for `Azure Kubernetes Service Cluster User Role` and `Azure Kubernetes Service RBAC Cluster Admin` in `main.tf` for the admin users.

### Incident 2: Key Vault Access Forbidden (`ForbiddenByRbac`)
* **Symptom:** `Caller is not authorized to perform action: Microsoft.KeyVault/vaults/secrets/getSecret/action` when fetching `database-url`.
* **Cause:** The active user lacked Key Vault permissions because Azure Key Vault uses RBAC instead of Access Policies.
* **Resolution:** Added `Key Vault Secrets Officer` role assignment in `main.tf` to the admin user principal IDs.

### Incident 3: Soft-Deleted Resource Conflicts (409 Conflict)
* **Symptom:** `FlagMustBeSetForRestore: An existing resource has been soft-deleted...` during Key Vault/AI deployment.
* **Cause:** Key Vault and OpenAI names are globally unique; previous resources were in a soft-deleted state.
* **Resolution:** Suffixes in `terraform.tfvars` were incremented (`-05` ➔ `-06` ➔ `-07`).

### Incident 4: Resource Group Deletion Blocked during Destroy
* **Symptom:** `deleting Resource Group "sathvik-rg": the Resource Group still contains Resources`.
* **Cause:** AKS dynamically created a `ContainerInsights` solution that wasn't managed directly by Terraform.
* **Resolution:** Configured `prevent_deletion_if_contains_resources = false` inside `providers.tf` for the `resource_group` block.

### Incident 5: AGIC Access Forbidden (403 Error)
* **Symptom:** AGIC logs showed `ErrorApplicationGatewayForbidden` and failed to update Application Gateway backend pools.
* **Cause:** The new cluster's AGIC identity lacked RBAC access to read/write the gateway configuration.
* **Resolution:** Added `Contributor` role on App Gateway, `Reader` on Resource Group, and `Network Contributor` on VNet to the AGIC managed identity object ID in `main.tf`.

### Incident 6: WAF Policy Blocking App Traffic
* **Symptom:** WAF rules block normal application operations.
* **Cause:** WAF was configured in strict `Prevention` mode.
* **Resolution:** Changed WAF mode to `Detection` in `modules/application-gateway/main.tf` to allow logs without blocking traffic.

### Incident 7: Argo CD Bad Gateway (502 Error)
* **Symptom:** `Bad Gateway` when loading `argocd.sathvikdevops.site`.
* **Cause:** Backend SSL protocol mismatch. The App Gateway was querying HTTP but Argo CD server expected HTTPS.
* **Resolution:** Configured Argo CD to run in insecure mode (`server.insecure: "true"` inside `argocd-cmd-params-cm`), restarted `argocd-server`, and changed the ingress backend port to `80`.

### Incident 8: Image Pull Backoff on QuickHaul Pods
* **Symptom:** `failed to pull and unpack image "docker.io/library/quickhaul-auth:dev-xxxx"`
* **Cause:** The registry prefix defaulted to docker.io because `global.imageRegistry` Helm parameter was not specified in Argo CD.
* **Resolution:** Updated the Argo CD Application manifest to inject `global.imageRegistry = resolveopsacr05.azurecr.io` under Helm parameters.

### Incident 9: Image Pull Backoff due to ACR Authorization (AcrPull)
* **Symptom:** Pods stuck in `ImagePullBackOff` showing `pull access denied` or `authorization failed` when pulling from `resolveopsacr05.azurecr.io`.
* **Cause:** The newly created AKS cluster's Kubelet Managed Identity lacked permissions to read/pull images from the Azure Container Registry (ACR).
* **Resolution:** Added the `AcrPull` role assignment in `main.tf` mapping the AKS Kubelet Identity (`kubelet_identity_object_id`) to the Container Registry (`acr.id`).

### Incident 10: MongoDB Authentication Failure in QuickHaul microservices
* **Symptom:** Pods run but log `FAILED to connect to MongoDB: Authentication failed` and fail their HTTP readiness/liveness probes, causing a `502 Bad Gateway` at the Application Gateway.
* **Cause:** MongoDB initializes users defined via `MONGO_INITDB_ROOT_USERNAME` inside the `admin` database. The microservice connection URI targeted `quickhaul_dev` database without specifying the auth database, causing MongoDB to look for the user in the wrong database.
* **Resolution:** 
  1. Wiped the old persistent volume claim (`quickhaul-mongodb-data`) to force MongoDB to initialize with the new password.
  2. Modified the Helm template (`quickhaul/helm/quickhaul/templates/deployment.yaml`) to append `?authSource=admin` to the generated `MONGO_URI` environment variable so that authentication requests are properly directed to the `admin` database.


