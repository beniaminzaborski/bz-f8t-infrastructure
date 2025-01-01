@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param createdBy string

param isProdResourceGroup bool

var environment = isProdResourceGroup ? 'prod' : 'nonprod'

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

output containerRegistryName string =  containerRegistry.name
