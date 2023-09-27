@description('Environment name')
@minLength(2)
@allowed(['dev', 'uat', 'prod'])
param environment string

@description('Azure region')
param location string
var shortLocation = substring(location, 0, 6)

@description('Project name')
@minLength(3)
param projectName string = 'f8t'

@description('The administrator username of the SQL logical server')
param dbAdminLogin string = 'postgres'

@secure()
param dbAdminPassword string

@description('Azure secondary region for CosmosDB')
param secondaryComosDbRegion string = 'northeurope'

var createdBy = 'Beniamin'

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${projectName}-${environment}-${shortLocation}'
  location: location
}

module k8sCluster 'modules/k8s-cluster.bicep' = {
  name: 'k8sClusterModule'
  scope: resourceGroup
  params: {
    createdBy: createdBy
    environment: environment
    location: location
    projectName: projectName
    shortLocation: shortLocation
  }
}

module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistryModule'
  scope: resourceGroup
  params: {
    location: location
    createdBy: createdBy
    environment: environment
    projectName: projectName
    shortLocation: shortLocation
  }
  dependsOn: [
    k8sCluster
   ]
}

module vaults 'modules/vaults.bicep' = {
  name: 'vaultModule'
  scope: resourceGroup
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
}

module observability 'modules/observability.bicep' = {
  name: 'observabilityModule'
  scope: resourceGroup
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
  dependsOn: [
    vaults
   ]
}

/*
module notification 'modules/notification.bicep' = {
  name: 'notificationModule'
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
  dependsOn: [
    vaults
  ]  
}
*/

module databases 'modules/databases.bicep' = {
  name: 'databaseModule'
  scope: resourceGroup
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
    dbAdminLogin: dbAdminLogin
    dbAdminPassword: dbAdminPassword
    //secondaryRegion: secondaryComosDbRegion
  }
  dependsOn: [
    vaults
  ]
}


module messaging 'modules/messaging.bicep' = {
  name: 'messagingModule'
  scope: resourceGroup
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
  dependsOn: [
    vaults
  ]   
}

/*
module storage 'modules/storage.bicep' = {
  name: 'storageModule'
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
  dependsOn: [
    vaults
  ]  
}
*/
