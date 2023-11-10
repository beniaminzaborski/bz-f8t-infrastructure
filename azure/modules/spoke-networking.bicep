@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param createdBy string

resource spokeVNet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-spoke-${projectName}-${shortLocation}'
  location: location
  tags: {
    createdBy: createdBy
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.300.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-fw-hub-${projectName}-${shortLocation}'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'snet-bas-hub-${projectName}-${shortLocation}'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}
