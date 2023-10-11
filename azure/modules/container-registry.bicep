@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

param aksPrincipalId string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: 'cr${projectName}${environment}${shortLocation}'
  location: location
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // Disable in PROD environment
    adminUserEnabled: true 
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

// Assign permission for AKS to pull images from ACR
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'bf578b4e-4a63-42a3-8411-be2bb39a5d74')

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(projectName, environment, location, aksPrincipalId, acrPullRoleDefinitionId)
  scope: containerRegistry
  properties: {
    principalId: aksPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleDefinitionId
  }
}
