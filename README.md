# Model Context Protocol (MCP) Server - .NET Implementation

This project contains a .NET web app implementation of a Model Context Protocol (MCP) server. The application is designed to be deployed to Azure App Service.

This project uses OAuth OBO, which allows users to authenticate via MCP, and then gives the MCP the ability to access downstream APIs on behalf of the user. In this example, it has been given access to Azure Resource Manager APIs.

The MCP server provides an API that follows the Model Context Protocol specification, allowing AI models to request additional context during inference.

## Key Features

- Complete implementation of the MCP protocol in C#/.NET using [MCP csharp-sdk](https://github.com/modelcontextprotocol/csharp-sdk)
- Azure App Service integration
- Custom tools support
- Support for OAUth OBO, giving the server the ability to access authenticated downstream APIs in the user's context.

## Project Structure

- `src/` - Contains the main C# project files
  - `Program.cs` - The entry point for the MCP server
  - `Tools/` - Contains custom tools that can be used by models via the MCP protocol
    - `AzureResourceManagerTools.cs` - Tools for performing basic Azure Resource Manager operations
- `infra/` - Contains Azure infrastructure as code using Bicep
  - `main.bicep` - Main infrastructure definition
  - `resources.bicep` - Resource definitions
  - `main.bicepparam` - Parameters for deployment

## Prerequisites

- [Azure Developer CLI](https://aka.ms/azd)
- [.NET 9 SDK](https://dotnet.microsoft.com/download)
- For local development with VS Code:
  - [Visual Studio Code](https://code.visualstudio.com/)

## Local Development

### Run the Server Locally

1. Clone this repository
2. Navigate to the project directory
   ```bash
   cd src
   ```
3. Install required packages
   ```bash
   dotnet restore
   ```
4. Run the project:
   ```bash
   dotnet run
   ```
4. The MCP server will be available at `http://localhost:5000`
5. When you're done, press Ctrl+C in the terminal to stop the app

### Testing the Available Tools

The server provides these tools:
- **AzureResourceManager**:
  - `get_subscriptions` - Get a list of Azure subscriptions
  - `get_resource_groups` - Get a list of Azure resource groups in a particular Azure subscription

### Connect to the Local MCP Server

#### Using VS Code - Copilot Agent Mode

1. **Add MCP Server** from command palette and add the URL to your running server's HTTP endpoint:
   ```
   http://localhost:5000
   ```
2. **List MCP Servers** from command palette and start the server
3. In Copilot chat agent mode, enter a prompt to trigger the tool:
   ```
   Fetch my Azure subscriptions
   ```
4. When prompted to run the tool, consent by clicking **Continue**

#### Using MCP Inspector

1. In a **new terminal window**, install and run MCP Inspector:
   ```bash
   npx @modelcontextprotocol/inspector
   ```
2. CTRL+click the URL displayed by the app (e.g. http://localhost:5173/#resources)
3. Set the transport type to `HTTP`
4. Set the URL to your running server's HTTP endpoint and **Connect**:
   ```
   http://localhost:5000
   ```
5. **List Tools**, click on a tool, and **Run Tool**

## Deploy to Azure

1. Login to Azure:
   ```bash
   azd auth login
   ```

2. Initialize your environment:
   ```bash
   azd env new
   ```

3. Deploy the application:
   ```bash
   azd up
   ```

4. Grant admin consent (Entra Portal UI) - first time only:
   * Open the Entra application in App Registrations
   * Select "Manage" -> "API Permissions", and press "Grant admin consent"

   This will:
   - Build the .NET application
   - Provision Azure resources defined in the Bicep templates
   - Deploy the application to Azure App Service

### Connect to Remote MCP Server

#### Using MCP Inspector
Use the web app's URL:
```
https://<webappname>.azurewebsites.net
```

#### Using VS Code - GitHub Copilot
Follow the same process as with the local app, but use your App Service URL:
```
https://<webappname>.azurewebsites.net
```

## Clean up resources

When you're done working with your app and related resources, you can use this command to delete the function app and its related resources from Azure and avoid incurring any further costs:

```shell
azd down
```