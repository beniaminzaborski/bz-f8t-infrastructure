@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param createdBy string

// TODO: Create in separate RG: rg-f8t-hub-poland

resource hubVNet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-hub-${projectName}-${shortLocation}'
  location: location
  tags: {
    createdBy: createdBy
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      { // TODO: Add subnet: AzureFirewallSubnet
        name: 'snet-fw-hub-${projectName}-${shortLocation}'
        properties: {
          addressPrefix: '10.0.1.0/26'
        }
      }
      // TODO: Add subnet: AzureFirewallManagementSubnet

      { // TODO: Add subnet AzureBastionSubnet
        name: 'snet-bas-hub-${projectName}-${shortLocation}'
        properties: {
          addressPrefix: '10.0.2.0/26'
        }
      }
    ]
  }
}

// TODO: Create Public IP for Bastion: pip-f8t-hub-bastion-poland

// TODO: Create Public IP for Firewall: pip-f8t-hub-firewall-poland

// TODO: Create Management Public IP for Firewall: pip-f8t-man-hub-firewall-poland - ONLY FOR BASIC !!!

// TODO: Create Bastion for VNET, with Subnet with PIP

// TODO: Create Azure Firewall with:
// - VNET
// - PIP
// - PIP for management - ONLY FOR BASIC !!!
// - create firewall policy

// TODO: Create VNET for DEV (differen address space than hub VNET - 10.1.0.0/16)

// TODO: Create VNET for QA *

// TODO: Create peering between HUB and DEV VNET
