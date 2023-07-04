@description('Azure region')
param location string = resourceGroup().location
var shortLocation = substring(location, 0, 6)

@description('Project name as a prefix for all resources')
@minLength(3)
param projectName string = 'f8t'

@description('The administrator username of the SQL logical server')
param dbAdminLogin string = 'postgres'

@secure()
param dbAdminPassword string

@description('Environment name')
@minLength(2)
@allowed(['dev', 'qa', 'stg', 'prd'])
param environment string

param secondaryComosDbRegion string = 'northeurope'

var createdBy = 'Beniamin'

module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistryModule'
  params: {
    location: location
    createdBy: createdBy
    environment: environment
    projectName: projectName
    shortLocation: shortLocation
  }
}

module k8sCluster 'modules/k8s-cluster.bicep' = {
  name: 'k8sClusterModule'
  params: {
    createdBy: createdBy
    environment: environment
    location: location
    projectName: projectName
    shortLocation: shortLocation
  }
  dependsOn: [
    containerRegistry
   ]
}

/*
module vaults 'modules/vaults.bicep' = {
  name: 'vaultModule'
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

module databases 'modules/databases.bicep' = {
  name: 'databaseModule'
  params: {
    location: location
    shortLocation: shortLocation
    projectName: projectName
    environment: environment
    createdBy: createdBy
    dbAdminLogin: dbAdminLogin
    dbAdminPassword: dbAdminPassword
    secondaryRegion: secondaryComosDbRegion
  }
  dependsOn: [
    vaults
  ]  
}

module messaging 'modules/messaging.bicep' = {
  name: 'messagingModule'
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
