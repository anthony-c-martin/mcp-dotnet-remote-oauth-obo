using 'main.bicep'

param name = readEnvironmentVariable('AZURE_ENV_NAME')

param location = readEnvironmentVariable('AZURE_LOCATION')

param appDetails = {
  displayName: 'Sample Remote MCP Server'
  description: 'Sample application for a remote ARM MCP server using OAuth OBO auth.'
}
