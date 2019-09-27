# aks-vmss-slb

# Pre-requisites
1. 'Az' PowerShell module
2. Use the 'Set-AzContext' cmdlet to select your desired Azure Subscription

# Usage
From a PowerShell command prompt execute ./scripts/deploy.ps1 to deploy the following reosurces

- Virtual Network
- AKS Cluster with VMSS & SLB
- AAD Service Principal
- Storage Account
- Azure Container Registry
