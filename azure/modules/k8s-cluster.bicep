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

// Assign permission for AKS to pull images from ACR
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aksCluster.id, acrPullRoleDefinitionId)
  properties: {
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleDefinitionId
  }
}
