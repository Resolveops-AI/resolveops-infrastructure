# ResolveOps & QuickHaul Deployment Runbook

This document details the step-by-step commands required to configure the administrative Jumpbox VM, authenticate with Azure, bootstrap Kubernetes resources, and deploy the application workloads into the user node pool.

---

## Phase 1: Jumpbox CLI Tool Setup
*Purpose: Install all required CLI utilities on the Ubuntu 22.04 Jumpbox VM to manage Azure and Kubernetes resources.*

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
*Purpose: Authenticate with Azure Active Directory and download the Kubernetes credentials to target the private AKS API server.*

```bash
# 1. Log in to your Azure account
az login

# 2. Fetch the credentials for the private cluster (overwriting existing if any)
az aks get-credentials --resource-group sathvik-rg --name resolveops-aks-05 --overwrite-existing

# 3. Verify that the nodes are reachable
kubectl get nodes -o wide
```

---

## Phase 3: Bootstrap Kubernetes Namespaces & Secrets
*Purpose: Create isolation boundaries and configure environment secrets required by workloads to connect to PostgreSQL.*

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
*Purpose: Allow ResolveOps AI pods to leverage Azure AD Federated Credentials to access cloud resources securely.*

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
*Purpose: Ensure all workload deployments target the userpool since the systempool is tainted and blocks application pods.*

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
*Purpose: Set up Argo CD in the cluster and establish GitOps CD pipelines to automatically synchronize the QuickHaul Helm chart.*

```bash
# 1. Add and update Argo CD repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 2. Install Argo CD
helm install argocd argo/argo-cd -n argocd

# 3. Fetch the auto-generated Argo CD Admin Password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# 4. Create the Argo CD Application Manifest
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
    # Corrected path to the chart
    path: quickhaul/helm/quickhaul
    helm:
      valueFiles:
        - values-dev.yaml
      # Inject the ACR Login Server parameter
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
*Purpose: Expose services publicly using Application Gateway rules mapped to your custom domains.*

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

### 3. Force AGIC Sync
```bash
# Restart the Ingress controller to program the Application Gateway immediately
kubectl delete pod -n kube-system -l app=ingress-appgw
```
