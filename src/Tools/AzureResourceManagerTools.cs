namespace McpServer.Tools;

using Azure.ResourceManager;
using Azure.ResourceManager.Resources;
using ModelContextProtocol.Server;
using System.ComponentModel;
using System.Text.Json;


[McpServerToolType]
public sealed class AzureResourceManagerTools(
    ArmClient armClient)
{
    [McpServerTool(Destructive = false, ReadOnly = true), Description("""
    Get a list of Azure subscriptions.
    """)]
    public async Task<string> GetSubscriptions()
    {
        List<ArmSubscription> subscriptions = [];
        await foreach (var subscription in armClient.GetSubscriptions().GetAllAsync())
        {
            subscriptions.Add(new()
            {
                Name = subscription.Data.DisplayName,
                Id = subscription.Data.SubscriptionId,
            });
        }

        return JsonSerializer.Serialize(subscriptions);
    }

    [McpServerTool(Destructive = false, ReadOnly = true), Description("""
    Get a list of Azure resource groups in a particular Azure subscription.
    """)]
    public async Task<string> GetResourceGroups(
        [Description("""
        The ID of the Azure subscription to retrieve resource groups for.
        """)] string subscriptionId)
    {
        var subscription = armClient.GetSubscriptionResource(SubscriptionResource.CreateResourceIdentifier(subscriptionId));

        List<ArmResourceGroup> resourceGroups = [];
        await foreach (var resourceGroup in subscription.GetResourceGroups())
        {
            resourceGroups.Add(new()
            {
                Name = resourceGroup.Data.Name,
                Location = resourceGroup.Data.Location,
                SubscriptionId = subscriptionId,
            });
        }

        return JsonSerializer.Serialize(resourceGroups);
    }
}

public partial class ArmSubscription
{
    public required string Name { get; set; }
    public required string Id { get; set; }
}

public partial class ArmResourceGroup
{
    public required string SubscriptionId { get; set; }
    public required string Name { get; set; }
    public required string Location { get; set; }
}