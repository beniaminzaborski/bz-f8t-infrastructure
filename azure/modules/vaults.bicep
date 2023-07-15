@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'f8t-github-actions-sp'
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}'
  location: location
  tags: {
    environment: environment
    createdBy: createdBy
  }
  properties: {
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    accessPolicies: [{
      objectId: managedIdentity.properties.principalId
      tenantId: subscription().tenantId
      permissions: {
        secrets: [
          'get'
        ]
      }
    }]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}
