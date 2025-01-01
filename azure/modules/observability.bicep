@minLength(3)
param projectName string

param location string

@description('Short resource group location name with limited characters')
param shortLocation string

@minLength(2)
param environment string

@minLength(2)
param createdBy string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${projectName}-${environment}-${shortLocation}'
  location: location
  tags: {
    createdBy: createdBy
    environment: environment
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${projectName}-${environment}-${shortLocation}'
  location: location
  tags: {
    environment: environment
    createdBy: createdBy
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    ImmediatePurgeDataOn30Days: true
    RetentionInDays: 30
  }
}

resource kvAppInsightsConnString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'kv-${projectName}-${environment}-${shortLocation}/ConnectionString-Fott-AppInsights'
  properties: {
    value: applicationInsights.properties.ConnectionString
  }
}

output logAnalyticsName string = logAnalytics.name
