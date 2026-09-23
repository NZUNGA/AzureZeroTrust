# 🔐 Secure Azure Infrastructure — Zero Trust Design

![Terraform](https://img.shields.io/badge/Terraform-1.7+-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Microsoft_Azure-canadacentral-0089D6?style=flat-square&logo=microsoftazure&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Status](https://img.shields.io/badge/Status-Deployed-success?style=flat-square)
![Security](https://img.shields.io/badge/Security-Zero_Trust-red?style=flat-square&logo=microsoftdefender&logoColor=white)
![IaC](https://img.shields.io/badge/IaC-GitHub_Actions_CI%2FCD-2088FF?style=flat-square&logo=githubactions&logoColor=white)

> Personal project demonstrating enterprise-grade Zero Trust architecture
> on Microsoft Azure using Terraform — deployed and tested against a real
> Azure tenant in canadacentral.

---

## 🏗️ Architecture overview

```
                    ┌─────────────────────────────────┐
                    │        Azure Tenant              │
                    │  ┌──────────────────────────┐   │
                    │  │   rg-zerotrust-dev        │   │
                    │  │                           │   │
                    │  │  ┌─────────┐  ┌────────┐ │   │
                    │  │  │ Bastion │  │  NSG   │ │   │
                    │  │  │Standard │  │ deny-* │ │   │
                    │  │  └────┬────┘  └────────┘ │   │
                    │  │       │                   │   │
                    │  │  ┌────▼──────────────┐   │   │
                    │  │  │    VNet 10.10/16  │   │   │
                    │  │  │  ┌─────────────┐  │   │   │
                    │  │  │  │  snet-app   │  │   │   │
                    │  │  │  │  snet-pe    │  │   │   │
                    │  │  │  │  Bastion    │  │   │   │
                    │  │  │  │  Firewall   │  │   │   │
                    │  │  │  └─────────────┘  │   │   │
                    │  │  └───────────────────┘   │   │
                    │  │                           │   │
                    │  │  ┌──────────┐ ┌────────┐ │   │
                    │  │  │Key Vault │ │  SQL   │ │   │
                    │  │  │RBAC+PE   │ │AAD-only│ │   │
                    │  │  └──────────┘ └────────┘ │   │
                    │  │                           │   │
                    │  │  ┌──────────────────────┐ │   │
                    │  │  │ Managed Identity      │ │   │
                    │  │  │ User-assigned · RBAC  │ │   │
                    │  │  └──────────────────────┘ │   │
                    │  └──────────────────────────┘   │
                    └─────────────────────────────────┘
```

---

## 🔑 Five architectural decisions

### 1 — Managed Identity only — no stored credentials
All Azure service connections use a **user-assigned Managed Identity**
with `DefaultAzureCredential`. No service principal secrets. No API keys.
No hardcoded credentials anywhere in the codebase.

User-assigned (not system-assigned) so the identity survives resource
replacement and can be reused across multiple resources.

### 2 — Key Vault RBAC model — not legacy access policies
`enable_rbac_authorization = true` on the Key Vault.

RBAC provides operation-level audit logs in Azure Monitor. Legacy access
policies are tenant-wide and not auditable per operation. The application
identity gets `Key Vault Secrets User` (read-only). Nothing gets
`Key Vault Administrator` except the Terraform deployer at provisioning time.
Public network access is explicitly disabled — Private Endpoint only.

### 3 — Private Endpoints on all PaaS services
Key Vault and Azure SQL are reachable only from inside the VNet via
Private Endpoint. Public network access is disabled at the resource level.
DNS resolution uses Azure Private DNS Zones — no split-horizon required.

```
privatelink.vaultcore.azure.net  →  kv-zerotrust-dev
privatelink.database.windows.net →  sql-zerotrust-dev
```

### 4 — Azure Bastion Standard eliminates public IPs on VMs
Standard SKU enables native RDP/SSH client tunneling. No VM in this
architecture has a public IP address. Combined with the `deny-public-ip-vm`
Azure Policy assignment, this is enforced at both the infrastructure and
governance layers.

### 5 — Azure Policy enforces governance at the resource group level
Three policy assignments enforced at `rg-zerotrust-dev`:

| Policy | Effect | Scope |
|---|---|---|
| Require mandatory tags (custom) | Audit | All indexed resources |
| Deny public IPs on network interfaces | Deny | All VMs |
| Require HTTPS on storage accounts | Audit | All storage |

---

## 📦 Resources deployed

| Resource | Name | Purpose |
|---|---|---|
| Resource Group | rg-zerotrust-dev | Container for all resources |
| Virtual Network | vnet-zerotrust-dev | Isolated network — 10.10.0.0/16 |
| Subnet — App | snet-app | App Service VNet integration |
| Subnet — Private Endpoints | snet-pe | PaaS private connectivity |
| Subnet — Bastion | AzureBastionSubnet | Secure VM access |
| Subnet — Firewall | AzureFirewallSubnet | Outbound FQDN control |
| NSG | nsg-app-dev | Explicit deny-internet-inbound |
| Azure Bastion | bas-zerotrust-dev | Standard SKU — no public VM IPs |
| Key Vault | kv-zerotrust-dev | RBAC model · PE · purge protected |
| Managed Identity | id-zerotrust-dev | User-assigned · scoped RBAC |
| Azure SQL Server | sql-zerotrust-dev | Entra ID-only auth |
| Azure SQL Database | sqldb-zerotrust | S1 tier |
| Private Endpoint | pe-kv-zerotrust-dev | Key Vault private connectivity |
| Private Endpoint | pe-sql-zerotrust-dev | SQL private connectivity |
| Private DNS Zone | privatelink.vaultcore.azure.net | Key Vault DNS |
| Private DNS Zone | privatelink.database.windows.net | SQL DNS |
| DNS VNet Link (×2) | pdnslink-kv / pdnslink-sql | Link DNS zones to VNet |
| Policy Assignment (×3) | — | Tag enforcement · No public IPs · HTTPS |
| Role Assignment (×2) | — | KV Secrets User · KV Administrator |

---

## 🔄 CI/CD pipeline

GitHub Actions runs on every pull request:

```
PR opened
    │
    ├── terraform fmt -check
    ├── terraform validate
    ├── tflint (linting)
    ├── Checkov security scan
    └── terraform plan → posted as PR comment
```

Apply only runs on merge to `main` with proper Azure credentials
configured as GitHub secrets.

---

## 🚀 How to deploy

### Prerequisites
- Terraform >= 1.7
- Azure CLI >= 2.50
- An Azure subscription
- Contributor role on the target subscription

### Remote state setup
```bash
az group create --name rg-tfstate --location canadacentral

az storage account create \
  --name YOUR_STORAGE_ACCOUNT \
  --resource-group rg-tfstate \
  --sku Standard_LRS \
  --allow-blob-public-access false

az storage container create \
  --name tfstate \
  --account-name stgtfstatenzgael
```

### Deploy
```bash
# Clone
git clone https://github.com/NZUNGA/AzureZeroTrust.git
cd AzureZeroTrust

# Authenticate
az login
az account set --subscription YOUR_SUBSCRIPTION_ID

# Create terraform.tfvars (never committed — see .gitignore)
cp terraform.tfvars.example terraform.tfvars
# Edit with your values

# Deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Destroy
```bash
terraform destroy
```

---

## 📋 Security controls summary

| Control | Implementation |
|---|---|
| No hardcoded credentials | Managed Identity + DefaultAzureCredential |
| No public IPs on VMs | Azure Bastion Standard + Azure Policy deny |
| No SQL passwords | Entra ID-only authentication |
| No Key Vault access policy | RBAC model with operation-level audit logs |
| No public PaaS endpoints | Private Endpoints + public access disabled |
| Mandatory tagging | Custom Azure Policy (Audit) |
| IaC security scanning | Checkov in GitHub Actions CI |
| State file protection | Azure Storage versioning enabled |

---

## 🎓 Certifications context

This project maps directly to the following certification domains:

- **AZ-305** — Design identity, governance, and monitoring solutions
- **SC-500** — Implement identity security · Defender for Cloud · Sentinel
- **AZ-104** — Configure Azure networking · NSGs · Bastion

---

## 👤 Author

**Gaël Nzunga** — Senior Systems Administrator · Azure Specialist · Montreal

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/gael-nzunga-263b3828/)
[![AZ-104](https://img.shields.io/badge/Microsoft-AZ--104_Certified-0089D6?style=flat-square&logo=microsoftazure&logoColor=white)](https://learn.microsoft.com/en-us/credentials/)
[![AZ-305](https://img.shields.io/badge/Microsoft-AZ--305_Oct_2026-0089D6?style=flat-square&logo=microsoftazure&logoColor=white)](https://learn.microsoft.com/en-us/credentials/)

---

> ⚠️ **Cost notice:** Azure Bastion Standard runs at ~$0.35/hour.
> Run `terraform destroy` when not actively using the environment.
> Re-deploy with `terraform apply` before demos or interviews.