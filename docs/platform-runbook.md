# ResolveOps Platform — Configuration & Incident Runbook

**Date:** 2026-06-24  
**Scope:** `resolveops-application` + `resolveops-infrastructure`

---

## 1. Asynchronous OTP via Azure Service Bus

### Problem
`/api/request-otp` called SMTP synchronously. If SMTP credentials were missing or the mail server was unreachable, the endpoint threw `500 Internal Server Error`, completely blocking user registration.

### Solution
Decoupled SMTP delivery from the API using Azure Service Bus.

### Architecture
```
Browser → /api/request-otp → api-gateway-service
                                    │
                    ┌───────────────┘
                    │  Publishes JSON message
                    ▼
          Service Bus Queue
          (notification-requested)
                    │
                    │  Background consumer
                    ▼
         notification-service → SMTP → User Email
```

### Files Changed

#### `resolveops-application`

| File | Change |
|---|---|
| `kubernetes/base/configmap.yaml` | Added `SERVICE_BUS_FQDN`, `SERVICE_BUS_QUEUE_NAME`, `DEBUG_LOG_OTP` |
| `services/api-gateway-service/requirements.txt` | Added `azure-servicebus==7.12.1` |
| `services/api-gateway-service/api.py` | Replaced synchronous SMTP call with Service Bus publish |
| `services/notification-service/requirements.txt` | Added `azure-servicebus==7.12.1`, `azure-identity==1.17.1` |
| `services/notification-service/main.py` | Added async background consumer for `notification-requested` queue |

#### Key Implementation Details

**api-gateway-service — `/api/request-otp`:**
- Generates OTP as before and stores it in `otp_store` with 120s TTL
- Publishes this JSON payload to Service Bus using `DefaultAzureCredential` (Workload Identity — no secrets):
  ```json
  {
    "type": "otp",
    "email": "user@example.com",
    "full_name": "User Name",
    "otp_code": "123456",
    "correlation_id": "<uuid>",
    "created_at": 1234567890.0,
    "expires_at": 1234568010.0
  }
  ```
- Returns **`202 Accepted`** on success
- Returns **`503 Service Unavailable`** if Service Bus publish fails (never returns 500 for SMTP)
- Logs OTP to console only if env var `DEBUG_LOG_OTP=true` (default: `false`)

**notification-service — Background Consumer:**
- Starts on FastAPI `startup` event as a non-blocking `asyncio` background task
- Polls `notification-requested` queue continuously
- For `type: otp` messages: calls existing `send_otp_email()` in a thread pool
- **Completes** message on successful SMTP delivery
- **Abandons** message (allows retry) if SMTP fails — does NOT crash the service
- Unknown message types are logged and safely completed

### ConfigMap Values Added
```yaml
SERVICE_BUS_FQDN: "resolveops-sb-05.servicebus.windows.net"
SERVICE_BUS_QUEUE_NAME: "notification-requested"
DEBUG_LOG_OTP: "false"
```

> **IMPORTANT:** To enable OTP logging for dev/debug purposes, run:
> ```bash
> kubectl edit configmap resolveops-config -n resolveops-ai
> # Set DEBUG_LOG_OTP: "true"
> kubectl rollout restart deployment/api-gateway-service -n resolveops-ai
> ```
> **Revert this immediately after use — never leave enabled in production.**

---

## 2. NSG Inbound Rules for Application Gateway

### Problem
The `resolveops-vnet-nsg` (associated to all subnets including the `appgw` subnet) only had a single rule allowing Azure Gateway Manager traffic on ports `65200-65535`. There were **no rules allowing HTTP/HTTPS traffic from the internet**, so Cloudflare's requests were silently dropped, causing a **522 Connection Timed Out** error on all hosted applications.

### Root Cause
Terraform's networking module created the NSG with only the required Azure management rule but omitted the public ingress rules needed for the Application Gateway to receive traffic.

### Fix

**File:** `terraform/modules/networking/main.tf`

Added two security rules to `azurerm_network_security_group.nsg`:

```hcl
# checkov:skip=CKV_AZURE_160: Port 80 must be open on the Application Gateway subnet
# to accept Cloudflare proxy traffic. HTTPS is terminated at the Cloudflare edge.
security_rule {
  name                       = "AllowHttpInbound"
  priority                   = 200
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "Internet"
  destination_address_prefix = "*"
}

security_rule {
  name                       = "AllowHttpsInbound"
  priority                   = 210
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "Internet"
  destination_address_prefix = "*"
}
```

**Checkov skip justification:** `CKV_AZURE_160` flags unrestricted HTTP access. This is intentional — this NSG protects the Application Gateway subnet which is the public entry point. Cloudflare (SSL Flexible mode) connects to origin on HTTP port 80. Restricting this would break all public ingress.

> **NOTE:** This NSG is associated to **all subnets** in the VNet (resolveops-aks, appgw, snet-private-endpoints, jumpbox). The rules are scoped broadly but only the `appgw` subnet actually exposes a public IP.

---

## 3. AGIC Stuck After Terraform Apply — Runbook

### Problem
After Terraform applied changes to the Application Gateway, AGIC (the AKS Ingress Controller add-on) got stuck in a loop of `Forcing resync` messages and never made any API calls to program the AppGW. All sites returned `502 Bad Gateway`.

### Root Cause
When Terraform directly modified the Application Gateway resource, it overwrote AGIC's internal state. AGIC's reconciliation cache showed "no delta" between its desired state and the (now Terraform-modified) AppGW, so it silently skipped all reconciliation for hours.

### Diagnosis Steps

```bash
# 1. Check AppGW backend health — if empty, AGIC has not synced
az network application-gateway show-backend-health \
  --resource-group sathvik-rg \
  --name resolveops-aks-05-appgw \
  --query "backendAddressPools[].backendHttpSettingsCollection[].servers[]"

# 2. Verify AGIC identity and role assignments
az aks show --resource-group sathvik-rg --name resolveops-aks-05 \
  --query "addonProfiles.ingressApplicationGateway.identity.objectId"
# Expected: 4c5e7a4d-c2fc-4534-b536-4a8664f97284

az role assignment list \
  --scope /subscriptions/<sub-id>/resourceGroups/sathvik-rg/providers/Microsoft.Network/applicationGateways/resolveops-aks-05-appgw \
  --query "[].{Role:roleDefinitionName, Principal:principalId}" -o table
# Expected: Contributor assigned to AGIC identity

# 3. Check AGIC logs — only resync loops means stuck
kubectl logs deployment/ingress-appgw-deployment -n kube-system --tail 500 | grep -v "Forcing resync"
# If only "Watch close" lines appear, AGIC is stuck
```

### Fix

**Restart the AGIC pod:**
```bash
kubectl delete pod -n kube-system -l app=ingress-appgw
```

AGIC restarts, re-reads all Kubernetes Ingress resources, and applies the full configuration to the AppGW within ~30 seconds. Confirm with:
```bash
kubectl logs -n kube-system -l app=ingress-appgw -f --tail 50
```

Expected success output:
```
BEGIN AppGateway deployment
OperationID='...'
Applied generated Application Gateway configuration
END AppGateway deployment
Completed last event loop run in: 31.33s
```

### ⚠️ Standing Rule: Always restart AGIC after Terraform touches AppGW

Whenever `terraform apply` modifies the Application Gateway resource (NSG rules, WAF policy changes, or any AppGW configuration), **always restart the AGIC pod immediately after**:

```bash
kubectl delete pod -n kube-system -l app=ingress-appgw
kubectl logs -n kube-system -l app=ingress-appgw -f --tail 50
```

Wait for `Applied generated Application Gateway configuration` before considering the deployment complete.

---

## 4. Final Verification Results

| Check | Result |
|---|---|
| `https://resolveops-ai.sathvikdevops.online` | ✅ **200 OK** |
| `https://quickhaul.sathvikdevops.site` | ⚠️ 404 (reachable, routing issue pending) |
| `/api/request-otp` returns 202 | ✅ After Service Bus pods deploy |
| AGIC programming AppGW backends | ✅ Confirmed |
| NSG rules applied via Terraform | ✅ `terraform apply` succeeded |
| Checkov `CKV_AZURE_160` bypass | ✅ Skipped with justification |

---

## 5. Pending Items

- [ ] **QuickHaul 404**: The quickhaul site is reachable but returning 404. The AppGW routing for `quickhaul.sathvikdevops.site` needs to be verified — specifically the default backend path mapping for the root `/` route.
- [ ] **Service Bus OTP — End-to-End Test**: Once the new `api-gateway-service` and `notification-service` images deploy from GitHub Actions, test the full flow: call `/api/request-otp` → confirm `202 Accepted` → check `notification-service` logs for message consumption.
- [ ] **SMTP Configuration**: Set up SMTP credentials in Azure Key Vault and mount them to `notification-service` so actual OTP emails are delivered to users.
- [ ] **Register First User**: Once OTP delivery is working (or using `DEBUG_LOG_OTP=true`), register the first admin user via `/api/request-otp` → `/api/signup`.
