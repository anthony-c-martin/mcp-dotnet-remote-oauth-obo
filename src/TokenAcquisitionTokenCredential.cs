namespace McpServer.Tools;

using Azure.Core;
using Microsoft.Identity.Web;

public class TokenAcquisitionTokenCredential(ITokenAcquisition tokenAcquisition) : TokenCredential
{
    public override AccessToken GetToken(TokenRequestContext requestContext, CancellationToken cancellationToken)
#pragma warning disable VSTHRD002 // Avoid problematic synchronous waits
        => GetTokenAsync(requestContext, CancellationToken.None).GetAwaiter().GetResult();
#pragma warning restore VSTHRD002 // Avoid problematic synchronous waits

    public override async ValueTask<AccessToken> GetTokenAsync(TokenRequestContext requestContext, CancellationToken cancellationToken)
    {
        var result = await tokenAcquisition.GetAuthenticationResultForUserAsync(requestContext.Scopes).ConfigureAwait(false);
        return new AccessToken(result.AccessToken, result.ExpiresOn);
    }
}