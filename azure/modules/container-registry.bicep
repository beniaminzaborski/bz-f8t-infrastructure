@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param createdBy string

param aksPrincipalId string

param isProdResourceGroup bool

var environment = isProdResourceGroup ? 'prod' : 'nonprod'

var containerRegistryName = isProdResourceGroup ? 'cr${projectName}${environment}${shortLocation}' : 'cr${projectName}${environment}${shortLocation}'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: containerRegistryName
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
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(projectName, environment, location, aksPrincipalId, acrPullRoleDefinitionId)
  scope: containerRegistry
  properties: {
    principalId: aksPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleDefinitionId
  }
}
