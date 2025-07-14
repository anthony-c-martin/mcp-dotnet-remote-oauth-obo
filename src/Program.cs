using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Web;
using ModelContextProtocol.AspNetCore.Authentication;
using McpServer.Tools;
using Microsoft.Extensions.Azure;
using TokenAcquisitionTokenCredential = McpServer.Tools.TokenAcquisitionTokenCredential;

var builder = WebApplication.CreateBuilder(args);

var serverUrl = builder.Configuration.GetValue<string>("ServerUrl") ?? throw new NullReferenceException();
var issuer = builder.Configuration.GetValue<string>("AzureAd:Issuer") ?? throw new NullReferenceException();
var authScope = builder.Configuration.GetValue<string>("AuthScope") ?? throw new NullReferenceException();

builder.Services.AddAuthentication(options =>
{
    options.DefaultChallengeScheme = McpAuthenticationDefaults.AuthenticationScheme;
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddMcp(options =>
{
    options.ResourceMetadata = new()
    {
        Resource = new Uri(serverUrl),
        AuthorizationServers = { new Uri(issuer) },
        BearerMethodsSupported = { "header" },
        ScopesSupported = { authScope },
    };
})
.AddMicrosoftIdentityWebApi(builder.Configuration, "AzureAd")
.EnableTokenAcquisitionToCallDownstreamApi()
.AddInMemoryTokenCaches()
.AddDownstreamApi("arm", builder.Configuration.GetSection("DownstreamApis:Arm"));

builder.Services.AddAuthorization();
builder.Services.AddHttpContextAccessor();

// Add MCP server services with HTTP transport
builder.Services.AddMcpServer()
    .WithHttpTransport(options =>
    {
        options.Stateless = true;
    })
    .WithTools<AzureResourceManagerTools>();

builder.Services
    .AddHttpClient();

builder.Services.AddSingleton<TokenAcquisitionTokenCredential>();

builder.Services.AddAzureClients(clientBuilder =>
{
    clientBuilder.AddArmClient("00000000-0000-0000-0000-000000000000");
    clientBuilder.UseCredential(provider => provider.GetRequiredService<TokenAcquisitionTokenCredential>());
});

// Add CORS for HTTP transport support in browsers
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

// Enable CORS
app.UseCors();

app.UseAuthentication();
app.UseAuthorization();

// Map MCP endpoints
app.MapMcp().RequireAuthorization();

app.MapGet("/health", () => Results.Ok(new { Timestamp = DateTime.UtcNow }));

app.Run();