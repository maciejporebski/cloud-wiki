using Azure.Core;
using Azure.Identity;

public class Program
{
    public static async Task Main(string[] args)
    {
        /*
         * Packages:
         * - Azure.Identity
         */

        // Create Credential
        string tenantId = "";
        InteractiveBrowserCredentialOptions interactiveCredentialOptions = new InteractiveBrowserCredentialOptions() { TenantId = tenantId };
        InteractiveBrowserCredential interactiveCredential = new InteractiveBrowserCredential(interactiveCredentialOptions);

        // Get Access Token
        string[] tokenScopes = new string[] { "" };
        TokenRequestContext tokenRequestContext = new TokenRequestContext(tokenScopes);
        AccessToken accessToken = await interactiveCredential.GetTokenAsync(tokenRequestContext);
        // accessToken.Token
        // accessToken.ExpiresOn
    }
}
