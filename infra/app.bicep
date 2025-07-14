extension microsoftGraphV1

import { AppDetails } from './types.bicep'

@description('The principle id of the user-assigned managed identity')
param userAssignedIdentityPrincipalId string

@description('The display name of the application in Entra ID')
param appDetails AppDetails

param resourceToken string

var scopeName = 'MCP.Access'
var scopeId = guid(resourceToken, scopeName)

var tenantId = tenant().tenantId
var loginEndpoint = environment().authentication.loginEndpoint

var appUniqueName = 'arm-mcp-poc-${resourceToken}'

resource app 'Microsoft.Graph/applications@v1.0' = {
  displayName: appDetails.displayName
  description: appDetails.description
  uniqueName: appUniqueName
  api: {
    oauth2PermissionScopes: [
      {
        id: guid(resourceToken, scopeName)
        adminConsentDescription: 'Allows the application to perform MCP operations on behalf of the signed-in user'
        adminConsentDisplayName: 'MCP Access'
        isEnabled: true
        type: 'User'
        userConsentDescription: 'Allows the app to perform MCP operations on your behalf'
        userConsentDisplayName: 'MCP Access'
        value: scopeName
      }
    ]
    requestedAccessTokenVersion: 2
    preAuthorizedApplications: [
      // VSCode
      {
        appId: 'aebc6443-996d-45c2-90f0-388ff96faa56'
        delegatedPermissionIds: [
          scopeId
        ]
      }
    ]
  }
  requiredResourceAccess: [
    {
      // Microsoft Graph - User.Read
      resourceAppId: '00000003-0000-0000-c000-000000000000'
      resourceAccess: [
        {
          id: 'e1fe6dd8-ba31-4d61-89e7-88639da4683d'
          type: 'Scope'
        }
      ]
    }
    {
      // ARM - user_impersonate
      resourceAppId: '797f4846-ba00-4fd7-ba43-dac1f8f63013'
      resourceAccess: [
        {
          id: '41094075-9dad-400e-a0bd-54e686782033'
          type: 'Scope'
        }
      ]
    }
  ]

  resource fic 'federatedIdentityCredentials@v1.0' = {
    name: '${app.uniqueName}/msiAsFic'
    description: 'Trust the user-assigned MI as a credential for the app'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: '${loginEndpoint}${tenantId}/v2.0'
    subject: userAssignedIdentityPrincipalId
  }
}

var identifierUri = 'api://${app.appId}'

// workaround for https://github.com/microsoftgraph/msgraph-bicep-types/issues/239
resource appWithIdentifierUris 'Microsoft.Graph/applications@v1.0' = {
  displayName: app.displayName
  description: app.description
  uniqueName: appUniqueName
  api: app.api
  identifierUris: [
    identifierUri
  ]
  requiredResourceAccess: app.requiredResourceAccess
}

resource servicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: appWithIdentifierUris.appId
}

output clientId string = app.appId
output authScope string = '${identifierUri}/${scopeName}'
