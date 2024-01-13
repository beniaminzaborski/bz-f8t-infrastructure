@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@description('Disk size in GB for cluster node')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The size of VM for cluster node')
param nodeVmSize string = 'standard_d2s_v3'

@description('Number of nodes in cluster')
@minValue(1)
@maxValue(50)
param nodeCount int = 2

@minLength(2)
param environment string

@minLength(2)
param createdBy string

resource aksPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-${projectName}-${environment}-${shortLocation}'
  location: location
  tags: {
    environment: environment
    createdBy: createdBy
  }
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource aksVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-aks-${projectName}-${environment}-${shortLocation}'
  location: location
  tags: {
    environment: environment
    createdBy: createdBy
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'agwSubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: 'agw-${projectName}-${environment}-${shortLocation}'
  location: location
  tags: {
    environment: environment
    createdBy: createdBy
  }
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    frontendIPConfigurations: [
      {
        name: 'publicFrontendIpConfig'
        id: aksPublicIp.id
      }
    ]
    frontendPorts: [
      {
        name: 'frontendPortConfig'
        properties: {
          port: 80
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'gatewayIpConfig'
        properties: {
          subnet: {
            id: aksVnet.properties.subnets[0].id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpSetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 3
    }
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-04-01' = {
  name: 'aks-${projectName}-${environment}-${shortLocation}'
  location: location
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
  properties: {
    dnsPrefix: 'aks${projectName}'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: nodeCount
        minCount: 1
        maxCount: 3
        enableAutoScaling: true
        osDiskSizeGB: osDiskSizeGB
        vmSize: nodeVmSize
        osType: 'Linux'
        mode: 'System'
      }
    ]
  }
}

output aksPrincipalId string = aksCluster.properties.identityProfile.kubeletidentity.objectId
