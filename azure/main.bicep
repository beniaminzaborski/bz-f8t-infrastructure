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

// Resource groups:
// 1. Shared resource group for hub network resources: rg-f8t-hub-westeu
// 2. Shared resource group for non-production environments such as dev or qa: rg-f8t-nonprod-westeu
// 3. Shared resource group for production environments such as uat or prod: rg-f8t-prod-westeu

var isProdResourceGroup = environment == 'uat' || environment == 'prod'
var envResourceGroupSuffix = isProdResourceGroup ? 'prod' : 'nonprod'
var envResourceGroupName = 'rg-${projectName}-${envResourceGroupSuffix}-${shortLocation}'

// resource hubResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
//   name: 'rg-${projectName}-hub-${shortLocation}'
//   location: location
// }

resource envResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: envResourceGroupName
  location: location
}

/*
module hubNetwork 'modules/hub-networking.bicep' = {
  name: 'hubNetworkModule'
  scope: hubResourceGroup
  params: {
    createdBy: createdBy
    location: location
    projectName: projectName
    shortLocation: shortLocation
  }
}

module spokeNetwork 'modules/spoke-networking.bicep' = {
  name: 'spokeNetworkModule'
  scope: envResourceGroup
  params: {
    createdBy: createdBy
    location: location
    projectName: projectName
    shortLocation: shortLocation
  }
}
*/

module k8sCluster 'modules/k8s-cluster.bicep' = {
  name: 'k8sClusterModule'
  scope: envResourceGroup
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
  scope: envResourceGroup
  params: {
    location: location
    createdBy: createdBy
    projectName: projectName
    shortLocation: shortLocation
    aksPrincipalId: k8sCluster.outputs.aksPrincipalId
    isProdResourceGroup: isProdResourceGroup
  }
  dependsOn: [
    k8sCluster
   ]
}

module vaults 'modules/vaults.bicep' = {
  name: 'vaultModule'
  scope: envResourceGroup
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
  scope: envResourceGroup
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
  scope: envResourceGroup
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
  scope: envResourceGroup
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
