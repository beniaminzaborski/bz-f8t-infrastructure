@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-04-01' = {
  name: 'aks-${projectName}-${environment}-${shortLocation}'
  location: location
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
  properties: {
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 2
        enableAutoScaling: true
      }
    ]
  }
}
