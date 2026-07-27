# azure-zero-trust-infra

Terraform project defining a secure Azure infrastructure
for a mid-size company (200 employees). Four workload
resource groups with zero-trust networking, private endpoints
on all PaaS services, and security controls aligned with
AZ-305 and SC-500 exam objectives.

Design decisions are documented in DECISIONS.md with the
reasoning behind each choice.

## Resource groups

- rg-contoso-network-prod: VNet, subnets, NSGs, Azure Firewall, Azure Bastion, Private DNS zones
- rg-contoso-compute-prod: VMs, App Service, AKS, user-assigned managed identities
- rg-contoso-storage-prod: Key Vault, storage accounts, Azure SQL, customer-managed encryption keys
- rg-contoso-ai-prod: Azure OpenAI, AI Search,API Management (AI gateway), Defender for AI
- rg-contoso-security-prod: Log Analytics Workspace, Microsoft Sentinel, Defender for Cloud plans
- rg-contoso-identity-prod: user-assigned managed identities

## Modules

**modules/network/**
- VNet (10.0.0.0/16) with 8 named subnets
- One NSG per subnet with explicit inbound and outbound rules
- Azure Firewall with application rules filtering outbound by FQDN
- Azure Bastion Standard SKU. No public IPs on any VM
- Private DNS zones for all PaaS services
- Route table forcing all compute and data subnet traffic
  through Azure Firewall

**modules/compute/**
- Windows Server VMs: No public IP, disk encryption with CMK, AADLoginForWindows extension, Azure Monitor agent
- App Service: VNet integration, public access disabled, Private Endpoint, Key Vault references for all secrets
- AKS: private cluster, CNI networking, Azure Policy enabled, Workload Identity, Defender for Containers
- User-assigned managed identities with scoped RBAC assignments

**modules/storage/**
- Key Vault: purge protection enabled, RBAC model,
  diagnostic logging to Log Analytics, Private Endpoint
- Disk Encryption Set using Key Vault RSA key for CMK
- Storage accounts: HTTPS only, min TLS 1.2, public access disabled, soft delete, versioning, Private Endpoints for blob and file
- Azure SQL: AAD-only authentication, TDE with CMK, auditing to Log Analytics, Defender for SQL, Private Endpoint

**modules/ai/**
- Azure OpenAI: local_auth_enabled = false (managed identity only), public access disabled, Private Endpoint, content filtering policy
- AI Search: local authentication disabled, private access only
- API Management (Standard, internal VNet mode): rate limiting, JWT validation, token tracking, Content Safety passthrough
- Defender for AI Services enabled

**shared/monitoring/**
- Log Analytics Workspace (90-day retention)
- Microsoft Sentinel on the workspace
- Defender for Cloud plans: VirtualMachines, AppServices,
  SqlServers, StorageAccounts, KeyVaults, CognitiveServices
- 5 Sentinel analytics rules (KQL): failed login spike,
  Key Vault after-hours access, new Global Admin added,
  AI token spike, Firewall block spike

## Security controls applied to every resource

Every VM: no public IP, disk encryption with CMK,
AAD login, Azure Monitor agent

Every PaaS service: Private Endpoint, public access disabled,
diagnostic logs to Log Analytics

Key Vault: purge protection, RBAC model, audit logging,
Private Endpoint

SQL: AAD-only authentication, TDE with CMK,
auditing, Defender for SQL

Azure OpenAI: no API keys, managed identity only,
content filtering, APIM gateway in front

## CI

GitHub Actions on every push:
- terraform validate
- tflint (Azure ruleset)
- checkov (CKV_AZURE_* checks)

## Terraform state

Remote state in Azure Storage with versioning and soft delete.
Created manually before any Terraform runs.
Not managed by this repository.

## Status

Work in progress. Modules built in dependency order:
monitoring → network → storage → compute → AI

## Certification alignment

AZ-305: identity and governance, data storage solutions,
business continuity, infrastructure solutions

SC-500: Domain 1 (identity and access), Domain 2 (networking
and storage), Domain 3 (compute and AI security),
Domain 4 (posture management and monitoring)
