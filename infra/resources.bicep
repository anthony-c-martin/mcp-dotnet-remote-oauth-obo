import { AppDetails } from './types.bicep'

param location string
param resourceToken string
param tags object
param appDetails AppDetails

@description('The SKU of App Service Plan.')
param sku string = 'P0V3'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'identity-${resourceToken}'
  location: location
}

var tenantId = tenant().tenantId
var loginEndpoint = environment().authentication.loginEndpoint
var armEndpoint = environment().resourceManager

module app 'app.bicep' = {
  params: {
    appDetails: appDetails
    resourceToken: resourceToken
    userAssignedIdentityPrincipalId: managedIdentity.properties.principalId
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-${resourceToken}'
  location: location
  sku: {
    name: sku
    capacity: 1
  }
  properties: {
    reserved: false
  }
}

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: 'app-${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  kind: 'app'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: true
    siteConfig: {
      minTlsVersion: '1.2'
      http20Enabled: true
      alwaysOn: true
      windowsFxVersion: 'DOTNET|9.0'
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'dotnet'
        }
      ]
    }
  }
  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
      WEBSITE_HTTPLOGGING_RETENTION_DAYS: '3'
      ServerUrl: 'https://app-${resourceToken}.azurewebsites.net'
      AuthScope: app.outputs.authScope
      'AzureAd:Instance': loginEndpoint
      'AzureAd:ClientId': app.outputs.clientId
      'AzureAd:Issuer': '${loginEndpoint}${tenantId}/v2.0'
      'AzureAd:TenantId': tenantId
      'AzureAd:Audience': app.outputs.clientId
      'AzureAd:ClientCredentials:0:SourceType': 'SignedAssertionFromManagedIdentity'
      'AzureAd:ClientCredentials:0:ManagedIdentityClientId': managedIdentity.properties.clientId
      'AzureAd:ClientCredentials:0:TokenExchangeUrl': 'api://AzureADTokenExchange'
      'DownstreamApis:Arm:BaseUrl': armEndpoint
      'DownstreamApis:Arm:Scopes:0': '${armEndpoint}/.default'
    }
  }
}

output WEB_URI string = 'https://${webApp.properties.defaultHostName}'
