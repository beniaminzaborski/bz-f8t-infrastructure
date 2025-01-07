@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param createdBy string

@minLength(2)
param environment string

param containerRegistryName string
param logAnalyticsName string
param keyVaultName string

// Define RBAC role to pull image from Container Registry
var acrPullRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Define RBAC role to get secret from Key Vault
var kvGetSecretRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

// Create user assigned identity for all container apps
resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'id-${projectName}-${environment}-${shortLocation}'
  location: location
  tags: {
    createdBy: createdBy
    environment: environment
  }
}

// Get existing container registry by name
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: containerRegistryName
}

// Add RBAC role for user assigned inentity to pull image from Container Registry
resource uaiRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, uai.id, acrPullRole)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRole
    principalId: uai.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Get existing Key Vault by name
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Add RBAC role for user assigned inentity to get secret from Key Vault
resource keyVaultRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, uai.id, kvGetSecretRole)
  scope: keyVault
  properties: {
    roleDefinitionId: kvGetSecretRole
    principalId: uai.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Get existing Log Analytics by name
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsName
}

// Create Container Apps Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-${projectName}-${environment}-${shortLocation}'
  location: location
  tags: {
    createdBy: createdBy
    environment: environment
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Create f8t-admin service Container App
resource adminContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-${projectName}-admin-${environment}-${shortLocation}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uai.id}': {}
    }
  }
  tags: {
    createdBy: createdBy
    environment: environment
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      secrets: [
        {
          name: 'connectionstrings-postgres-kv'
          keyVaultUrl: 'https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-Fott-Administration-Postgres'
          identity: uai.id
        }
        {
          name: 'connectionstrings-azureservicebus-kv'
          keyVaultUrl: 'https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-Fott-ServiceBus'
          identity: uai.id
        }
        {
          name: 'connectionstrings-applicationinsights-kv'
          keyVaultUrl: 'https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-Fott-AppInsights'
          identity: uai.id
        }
      ]
      ingress: {
        external: true
        targetPort: 8080
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          identity: uai.id
          server: containerRegistry.properties.loginServer
        }
      ]
      activeRevisionsMode: 'Single'
    }
    template: {
      containers: [
        {
          name: 'f8t-admin'
          image: '${containerRegistry.properties.loginServer}/bz-f8t-admin:latest'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'ConnectionStrings__Postgres'
              secretRef: 'connectionstrings-postgres-kv'
            }
            {
              name: 'ConnectionStrings__AzureServiceBus'
              secretRef: 'connectionstrings-azureservicebus-kv'
            }
            {
              name: 'ConnectionStrings__ApplicationInsights'
              secretRef: 'connectionstrings-applicationinsights-kv'
            }
          ]
          resources: {
            cpu: json('.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-requests'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

// Create f8t-chatbot service Container App
resource chatbotContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-${projectName}-chatbot-${environment}-${shortLocation}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uai.id}': {}
    }
  }
  tags: {
    createdBy: createdBy
    environment: environment
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      secrets: [
        {
          name: 'connectionstrings-applicationinsights-kv'
          keyVaultUrl: 'https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-Fott-AppInsights'
          identity: uai.id
        }
      ]
      ingress: {
        external: true
        targetPort: 8081
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          identity: uai.id
          server: containerRegistry.properties.loginServer
        }
      ]
      activeRevisionsMode: 'Single'
    }
    template: {
      containers: [
        {
          name: 'f8t-chatbot'
          image: '${containerRegistry.properties.loginServer}/bz-f8t-chatbot:latest'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'ConnectionStrings__ApplicationInsights'
              secretRef: 'connectionstrings-applicationinsights-kv'
            }
          ]
          resources: {
            cpu: json('.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-requests'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}
