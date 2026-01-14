# Secure React App and .NET API with Microsoft Entra ID

## Table of Contents
- [Introduction](#introduction)
- [Architecture Overview](#architecture-overview)
- [Authentication and Authorization Flow](#authentication-and-authorization-flow)
- [Prerequisites](#prerequisites)
- [Azure Entra ID Configuration](#azure-entra-id-configuration)
- [Terraform Setup](#terraform-setup)
- [React Application Configuration](#react-application-configuration)
- [.NET API Configuration](#net-api-configuration)
- [Running the Applications](#running-the-applications)
- [Common Pitfalls and Troubleshooting](#common-pitfalls-and-troubleshooting)

## Introduction

This project demonstrates how to secure a React Single Page Application (SPA) and a .NET Web API using Microsoft Entra ID (formerly Azure Active Directory). The React frontend uses the Microsoft Authentication Library (MSAL) for authentication, while the .NET API validates JWT tokens issued by Entra ID.

**Key Features:**
- User authentication via Entra ID in a React SPA
- Protected API endpoints using JWT bearer tokens
- OAuth 2.0 authorization code flow with PKCE
- Automated Azure infrastructure provisioning with Terraform
- Delegated permissions and admin consent management

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Microsoft Entra ID (Identity Platform)          │
│  ┌──────────────────────┐          ┌─────────────────────────┐     │
│  │  SPA App Registration │          │  API App Registration   │     │
│  │  (my-spa-app)        │          │  (my-api-app)           │     │
│  │  - Client ID         │          │  - Client ID            │     │
│  │  - Redirect URIs     │          │  - Exposed Scopes       │     │
│  │  - API Permissions   │          │  - App ID URI           │     │
│  └──────────────────────┘          └─────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
           ▲                                      ▲
           │ 1. Login Request                     │ 4. Validate Token
           │ 2. ID Token + Access Token           │
           │                                      │
    ┌──────┴───────┐                       ┌─────┴──────┐
    │ React SPA    │                       │ .NET API   │
    │ (Port 3000)  │──3. API Call + Token──│ (Port 5xxx)│
    │              │                       │            │
    │ - MSAL.js    │                       │ - JWT Auth │
    │ - React      │                       │ - ASP.NET  │
    └──────────────┘                       └────────────┘
```

**Component Responsibilities:**

1. **React SPA (Frontend)**
   - Authenticates users via MSAL.js library
   - Acquires access tokens for API calls
   - Manages user session and token refresh
   - Makes authenticated requests to the .NET API

2. **.NET API (Backend)**
   - Validates JWT bearer tokens from Entra ID
   - Enforces authorization policies
   - Exposes protected endpoints
   - Returns data only to authenticated and authorized users

3. **Microsoft Entra ID**
   - Issues ID tokens and access tokens
   - Manages user identities and authentication
   - Enforces consent for delegated permissions
   - Provides token validation endpoints

## Authentication and Authorization Flow

The application uses the **OAuth 2.0 Authorization Code Flow with PKCE** for secure authentication:

```
┌──────────┐                                                     ┌─────────────┐
│  User    │                                                     │  Entra ID   │
└────┬─────┘                                                     └──────┬──────┘
     │                                                                  │
     │ 1. Click "Sign In"                                              │
     ├──────────────────┐                                              │
     │                  │                                              │
┌────▼─────┐            │                                              │
│ React SPA│            │                                              │
└────┬─────┘            │                                              │
     │ 2. Redirect to Entra ID with code_challenge (PKCE)             │
     ├─────────────────────────────────────────────────────────────────▶
     │                                                                  │
     │                  3. User enters credentials & consents          │
     │                  ◀────────────────────────────────────────────┐ │
     │                                                                │ │
     │ 4. Authorization code returned via redirect                   │ │
     ◀─────────────────────────────────────────────────────────────────┤
     │                                                                  │
     │ 5. Exchange code for tokens (with code_verifier)                │
     ├─────────────────────────────────────────────────────────────────▶
     │                                                                  │
     │ 6. ID Token + Access Token returned                             │
     ◀─────────────────────────────────────────────────────────────────┤
     │                                                                  │
     │ 7. Store tokens in browser storage                              │
     ├──────────────────┐                                              │
     │                  │                                              │
     │ 8. User clicks to call API                                      │
     ├──────────────────┘                                              │
     │                                                                  │
     │ 9. Acquire access token (cached or refresh)                     │
     ├──────────────────┐                                              │
     │                  │                                         ┌────▼─────┐
     │ 10. Call API with Bearer token                            │ .NET API │
     ├────────────────────────────────────────────────────────────▶          │
     │                                                             │          │
     │                  11. Validate token signature & claims     │          │
     │                  ◀──────────────────────────────────────┐  │          │
     │                                                          │  │          │
     │ 12. Return protected data                                │  │          │
     ◀────────────────────────────────────────────────────────────┤          │
     │                                                             └──────────┘
```

**Step-by-Step Flow:**

1. **User Initiates Login**: User clicks "Sign In" button in React app
2. **MSAL Redirects**: MSAL.js redirects to Entra ID with PKCE code challenge
3. **User Authentication**: User enters credentials and consents to permissions
4. **Authorization Code**: Entra ID redirects back with authorization code
5. **Token Exchange**: MSAL exchanges code for tokens using PKCE code verifier
6. **Token Storage**: ID and access tokens stored in browser localStorage
7. **API Call Preparation**: User action triggers API call
8. **Token Acquisition**: MSAL acquires valid access token (from cache or refresh)
9. **Authenticated Request**: React app calls API with Bearer token in Authorization header
10. **Token Validation**: .NET API validates token signature, issuer, audience, and expiration
11. **Authorization Check**: API verifies user has required scopes/claims
12. **Protected Response**: API returns data to authenticated user

**Token Types:**

- **ID Token**: Contains user identity claims (name, email, etc.) - used by React app
- **Access Token**: Grants access to protected API resources - sent to .NET API
- **Refresh Token**: Used to obtain new access tokens when they expire (handled automatically by MSAL)

## Prerequisites

Before getting started, ensure you have the following:

### Software Requirements
- **Node.js** (v16 or later) and **npm** - [Download](https://nodejs.org/)
- **.NET 8 SDK** - [Download](https://dotnet.microsoft.com/download)
- **Terraform** (v1.0 or later) - [Download](https://www.terraform.io/downloads)
- **Azure CLI** - [Download](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **Git** - [Download](https://git-scm.com/)

### Azure Requirements
- **Microsoft Entra ID Tenant**: Access to an Azure tenant (create one at [entra.microsoft.com](https://entra.microsoft.com))
- **Azure Subscription**: Active Azure subscription (free tier works)
- **Permissions**: Ability to create App Registrations and grant admin consent
  - Minimum role: **Application Administrator** or **Global Administrator**

### Knowledge Prerequisites
- Basic understanding of OAuth 2.0 and OpenID Connect
- Familiarity with React and JavaScript/TypeScript
- Understanding of ASP.NET Core Web APIs
- Basic knowledge of Terraform (optional, but helpful)

## Azure Entra ID Configuration

This project uses **Terraform** to automate the creation of App Registrations and configuration. However, understanding what's being configured is essential for troubleshooting and manual setup if needed.

### Required App Registrations

Two app registrations are required:

#### 1. API App Registration (`my-api-app`)

This represents the .NET Web API that will be protected.

**Configuration:**
- **Display Name**: `my-api-app`
- **Supported Account Types**: Single tenant (accounts in your organizational directory only)
- **Redirect URIs**: 
  - Type: Web
  - URI: `https://localhost/api-callback` (not used in this minimal API, but configured for completeness)
- **Exposed API (Scopes)**:
  - **Scope Name**: `access_as_user`
  - **Scope ID**: `11111111-1111-1111-1111-111111111111` (UUID)
  - **Admin Consent Display Name**: "Access API"
  - **Admin Consent Description**: "Allow access to the API"
  - **User Consent**: Enabled for users
- **App ID URI**: `api://{client-id}` (automatically generated)

**Purpose**: This registration defines the API as a protected resource and exposes the `access_as_user` scope that the React app will request.

#### 2. SPA App Registration (`my-spa-app`)

This represents the React Single Page Application.

**Configuration:**
- **Display Name**: `my-spa-app`
- **Supported Account Types**: Single tenant
- **Redirect URIs**: 
  - Type: Single-page application (SPA)
  - URI: `http://localhost:3000` (where React dev server runs)
- **API Permissions** (Delegated):
  - **Custom API** (`my-api-app`):
    - `access_as_user` (requires admin consent)
  - **Microsoft Graph**:
    - `openid` - Sign users in
    - `profile` - View users' basic profile
    - `email` - View users' email address
    - `User.Read` - Read user profile
- **Authentication Settings**:
  - Access tokens: Enabled (for implicit flow, though not used with PKCE)
  - ID tokens: Enabled
  - Allow public client flows: No (using PKCE, not public client)

**Purpose**: This registration represents the React app as a client that can authenticate users and request access to the API.

### Admin Consent

Admin consent is **required** for the SPA to access the custom API. Terraform automatically grants this consent via:

```hcl
resource "azuread_service_principal_delegated_permission_grant" "spa_to_api" {
  service_principal_object_id          = azuread_service_principal.spa_sp.object_id
  resource_service_principal_object_id = azuread_service_principal.api_sp.object_id
  claim_values                         = ["access_as_user"]
}
```

**Manual Admin Consent** (if needed):
1. Navigate to Entra ID portal → App Registrations → `my-spa-app`
2. Go to **API permissions**
3. Click **Grant admin consent for {your tenant}**
4. Confirm the consent

### Scopes and Permissions Explained

**Scopes** define what the React app can do on behalf of the user:

- **`api://{api-client-id}/access_as_user`**: Custom scope to access the .NET API
- **`openid`**: Required for OpenID Connect sign-in
- **`profile`**: Access to basic profile information (name, picture)
- **`email`**: Access to user's email address
- **`User.Read`**: Read user profile from Microsoft Graph

When a user signs in, they consent to the app accessing these resources on their behalf.

## Terraform Setup

The project includes Terraform configuration to automate Azure Entra ID resource provisioning.

### Terraform Project Structure

```
terraform/
├── main.tf                          # Main orchestration file
├── providers.tf                     # Azure AD provider configuration
├── apps/
│   ├── api_app.tf                   # API app registration (legacy, see main.tf)
│   └── spa_app.tf                   # SPA app registration (legacy, see main.tf)
└── modules/
    └── entra_app_registration/
        ├── main.tf                   # App registration resource definition
        ├── variables.tf              # Input variables
        └── outputs.tf                # Outputs (client IDs, scope IDs)
```

### Terraform Configuration Overview

The `main.tf` file orchestrates the creation of both app registrations:

**API App Module:**
```hcl
module "api_app" {
  source      = "./modules/entra_app_registration"
  display_name = "my-api-app"
  web_redirect_uris = ["https://localhost/api-callback"]
  expose_scope = true
  
  scope_id   = "11111111-1111-1111-1111-111111111111"
  scope_value = "access_as_user"
  scope_admin_consent_description  = "Allow access to the API"
  scope_admin_consent_display_name = "Access API"
}
```

**SPA App Module:**
```hcl
module "spa_app" {
  source         = "./modules/entra_app_registration"
  display_name   = "my-spa-app"
  redirect_uris  = ["http://localhost:3000"]
  
  required_resource_access = [
    {
      resource_app_id = module.api_app.client_id  # Reference to API app
      resource_access = [
        {
          id   = module.api_app.scope_id
          type = "Scope"
        }
      ]
    },
    # Microsoft Graph permissions...
  ]
}
```

**Key Features:**
- **Modular Design**: Reusable `entra_app_registration` module
- **Dependency Management**: SPA app automatically references API app's client ID and scope ID
- **Admin Consent Automation**: Automatically grants admin consent via service principal delegation
- **Output Values**: Exports client IDs and scope IDs for use in application configuration

### Step-by-Step Terraform Guide

#### 1. Authenticate with Azure

```bash
# Login to Azure CLI
az login

# Set your subscription (if you have multiple)
az account set --subscription "your-subscription-id"

# Verify authentication
az account show
```

#### 2. Navigate to Terraform Directory

```bash
cd terraform/
```

#### 3. Initialize Terraform

This downloads the Azure AD provider and initializes the backend:

```bash
terraform init
```

**Expected Output:**
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azuread versions matching "~> 2.47"...
- Installing hashicorp/azuread v2.47.0...

Terraform has been successfully initialized!
```

#### 4. Review the Execution Plan

Preview what Terraform will create:

```bash
terraform plan
```

**What to Look For:**
- Two `azuread_application` resources (API and SPA)
- Two `azuread_service_principal` resources
- Two `azuread_service_principal_delegated_permission_grant` resources
- Total: ~6 resources to be created

#### 5. Apply the Configuration

Create the resources in Azure:

```bash
terraform apply
```

Type `yes` when prompted to confirm.

**Expected Output:**
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

api_app_client_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
spa_app_client_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
```

#### 6. Capture Output Values

Save the client IDs for application configuration:

```bash
# Display outputs
terraform output

# Save to a file (optional)
terraform output -json > outputs.json
```

**Important Values to Note:**
- `api_app_client_id`: Use in .NET API `appsettings.json`
- `spa_app_client_id`: Use in React `authConfig.js`

#### 7. Verify in Azure Portal (Optional)

1. Navigate to [entra.microsoft.com](https://entra.microsoft.com)
2. Go to **Applications** → **App registrations**
3. Select **All applications** tab
4. Verify `my-api-app` and `my-spa-app` are listed
5. Check API permissions and admin consent status

### Terraform Commands Reference

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize Terraform working directory |
| `terraform plan` | Preview changes without applying |
| `terraform apply` | Create/update resources |
| `terraform destroy` | Delete all managed resources |
| `terraform output` | Display output values |
| `terraform state list` | List all resources in state |
| `terraform show` | Show detailed resource information |

### Updating Configuration

If you need to modify the configuration:

1. Edit the relevant `.tf` files
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to apply changes

**Example: Change Redirect URI**
```hcl
# In main.tf, modify:
module "spa_app" {
  redirect_uris = ["http://localhost:3001"]  # Changed from 3000
  # ...
}
```

Then apply:
```bash
terraform apply
```

## React Application Configuration

The React application uses MSAL (Microsoft Authentication Library) to handle authentication.

### MSAL Overview

**MSAL.js** is Microsoft's official library for integrating Entra ID authentication in JavaScript applications. Key features:

- **Automatic Token Management**: Handles token acquisition, caching, and renewal
- **PKCE Support**: Uses secure Authorization Code Flow with PKCE (Proof Key for Code Exchange)
- **React Hooks**: Provides `useMsal`, `useIsAuthenticated`, `useAccount` hooks
- **Silent Token Acquisition**: Automatically refreshes tokens without user interaction
- **Error Handling**: Built-in retry logic and error handling

### Installation

The required packages are already installed in the `msal-react-app` directory:

```json
{
  "dependencies": {
    "@azure/msal-browser": "^4.16.0",
    "@azure/msal-react": "^3.0.16"
  }
}
```

To install in a new project:
```bash
npm install @azure/msal-browser @azure/msal-react
```

### MSAL Configuration (`src/authConfig.js`)

The `authConfig.js` file contains the MSAL configuration:

```javascript
export const msalConfig = {
  auth: {
    clientId: "YOUR_CLIENT_ID",           // From Terraform output: spa_app_client_id
    authority: "https://login.microsoftonline.com/YOUR_TENANT_ID",
    redirectUri: "http://localhost:3000",
  },
  cache: {
    cacheLocation: "localStorage",        // Use "sessionStorage" for more security
    storeAuthStateInCookie: false,        // Set to true for IE11 support
  },
};

export const loginRequest = {
  scopes: ["User.Read"],                   // Can also include custom API scopes
};
```

**Configuration Options Explained:**

- **`clientId`**: The Application (client) ID from the SPA app registration
  - Get from: Terraform output or Azure Portal → App registrations → my-spa-app → Overview
  
- **`authority`**: The Entra ID authority URL
  - Format: `https://login.microsoftonline.com/{tenant-id}`
  - For single tenant: Use your tenant ID or domain name
  - For multi-tenant: Use `https://login.microsoftonline.com/common`
  - Get tenant ID from: Azure Portal → Entra ID → Overview → Tenant ID

- **`redirectUri`**: Where Entra ID redirects after authentication
  - Must match the redirect URI configured in app registration
  - For local development: `http://localhost:3000`
  - For production: Your production URL (e.g., `https://app.example.com`)

- **`cacheLocation`**: Where tokens are stored
  - `"localStorage"`: Persists across browser sessions (default)
  - `"sessionStorage"`: Cleared when browser is closed (more secure)

- **`storeAuthStateInCookie`**: Store auth state in cookies
  - Set to `true` for IE11/Edge Legacy support
  - Set to `false` for modern browsers (more secure)

**Adding Custom API Scopes:**

To call your .NET API, update `loginRequest`:

```javascript
export const loginRequest = {
  scopes: [
    "User.Read",                                           // Microsoft Graph
    "api://{API_CLIENT_ID}/access_as_user"                // Custom API scope
  ],
};
```

Replace `{API_CLIENT_ID}` with the API app's client ID from Terraform output.

### MSAL Initialization (`src/index.js`)

The `index.js` file initializes MSAL and wraps the app with `MsalProvider`:

```javascript
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { PublicClientApplication } from "@azure/msal-browser";
import { MsalProvider } from "@azure/msal-react";
import { msalConfig } from "./authConfig";

// Create MSAL instance
const msalInstance = new PublicClientApplication(msalConfig);

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <MsalProvider instance={msalInstance}>
    <App />
  </MsalProvider>
);
```

**How It Works:**

1. **`PublicClientApplication`**: Creates an MSAL instance with your config
2. **`MsalProvider`**: React context provider that makes MSAL available throughout the app
3. All child components can now use MSAL hooks (`useMsal`, `useIsAuthenticated`, etc.)

### Authentication UI (`src/App.js`)

The `App.js` file contains the authentication UI components:

```javascript
import React from "react";
import { useMsal, useIsAuthenticated } from "@azure/msal-react";
import { loginRequest } from "./authConfig";

const SignInButton = () => {
  const { instance } = useMsal();
  const handleLogin = () => {
    instance.loginRedirect(loginRequest);
  };
  return <button onClick={handleLogin}>Sign In</button>;
};

const SignOutButton = () => {
  const { instance } = useMsal();
  const handleLogout = () => {
    instance.logoutRedirect();
  };
  return <button onClick={handleLogout}>Sign Out</button>;
};

const WelcomeUser = () => {
  const { accounts } = useMsal();
  return <h2>Welcome, {accounts[0]?.username}</h2>;
};

function App() {
  const isAuthenticated = useIsAuthenticated();

  return (
    <div style={{ padding: "20px" }}>
      <h1>React + Entra ID (MSAL.js)</h1>
      {isAuthenticated ? (
        <>
          <WelcomeUser />
          <SignOutButton />
        </>
      ) : (
        <SignInButton />
      )}
    </div>
  );
}

export default App;
```

**Key MSAL Hooks:**

- **`useMsal()`**: Access to MSAL instance and user accounts
  - `instance`: MSAL instance for login/logout
  - `accounts`: Array of signed-in user accounts

- **`useIsAuthenticated()`**: Boolean indicating if user is authenticated

- **`useAccount()`**: Access to the current user account details

**Login Methods:**

- **`loginRedirect()`**: Redirects to Entra ID for login (recommended for SPAs)
- **`loginPopup()`**: Opens login in a popup window (alternative, may be blocked)

**Logout Methods:**

- **`logoutRedirect()`**: Logs out and redirects to Entra ID logout page
- **`logoutPopup()`**: Logs out in a popup window

### Calling Protected APIs

To call your protected .NET API, acquire an access token and include it in the request:

```javascript
import { useMsal } from "@azure/msal-react";

function CallApiComponent() {
  const { instance, accounts } = useMsal();

  const callApi = async () => {
    // Define token request for your API
    const tokenRequest = {
      scopes: ["api://{API_CLIENT_ID}/access_as_user"],
      account: accounts[0]
    };

    try {
      // Acquire token silently (from cache or refresh)
      const response = await instance.acquireTokenSilent(tokenRequest);
      const accessToken = response.accessToken;

      // Call API with token
      const apiResponse = await fetch("https://localhost:5001/weatherforecast", {
        headers: {
          'Authorization': `Bearer ${accessToken}`
        }
      });

      const data = await apiResponse.json();
      console.log(data);
    } catch (error) {
      // If silent acquisition fails, fall back to interactive
      if (error.name === "InteractionRequiredAuthError") {
        const response = await instance.acquireTokenPopup(tokenRequest);
        const accessToken = response.accessToken;
        // Retry API call with new token...
      }
    }
  };

  return <button onClick={callApi}>Call API</button>;
}
```

**Token Acquisition Flow:**

1. **`acquireTokenSilent()`**: Attempts to get token from cache or refresh it
2. If silent acquisition fails, fall back to **`acquireTokenPopup()`** or **`acquireTokenRedirect()`**
3. Include token in `Authorization: Bearer {token}` header
4. MSAL automatically handles token refresh when tokens expire

## .NET API Configuration

The .NET API uses Microsoft.Identity.Web to validate JWT tokens from Entra ID.

### Dependencies

The API project includes the following NuGet packages (already in `MyApi.csproj`):

```xml
<PackageReference Include="Microsoft.Identity.Web" Version="3.11.0" />
<PackageReference Include="Microsoft.Identity.Web.MicrosoftGraph" Version="3.11.0" />
```

### Configuration (`appsettings.json`)

The API requires Entra ID configuration in `appsettings.json`:

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "<your-tenant-id>",
    "ClientId": "<your-api-client-id>",
    "Audience": "api://<your-api-client-id>"
  }
}
```

**Configuration Values:**

- **`Instance`**: Entra ID login endpoint (constant: `https://login.microsoftonline.com/`)
- **`TenantId`**: Your Azure AD tenant ID
  - Get from: Azure Portal → Entra ID → Overview → Tenant ID
- **`ClientId`**: The API app registration's client ID
  - Get from: Terraform output `api_app_client_id`
- **`Audience`**: The expected audience in access tokens
  - Format: `api://{api-client-id}`
  - Must match the App ID URI in the app registration

**Note:** Never commit actual secrets to source control. Use environment variables, Azure Key Vault, or user secrets for sensitive configuration:

```bash
# Using .NET user secrets (development)
dotnet user-secrets set "AzureAd:TenantId" "your-tenant-id"
dotnet user-secrets set "AzureAd:ClientId" "your-api-client-id"
```

### API Implementation (`Program.cs`)

The `Program.cs` file configures JWT authentication:

```csharp
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Web;

var builder = WebApplication.CreateBuilder(args);

// Add authentication with Microsoft Identity Web
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

// Add authorization
builder.Services.AddAuthorization();

var app = builder.Build();

// Use authentication & authorization middleware
app.UseAuthentication();
app.UseAuthorization();

// Protected endpoint example
app.MapGet("/weatherforecast", () =>
{
    // API logic here...
})
.RequireAuthorization()  // Requires valid JWT token
.WithName("GetWeatherForecast");

app.Run();
```

**How Token Validation Works:**

1. **`AddMicrosoftIdentityWebApi()`**: Configures JWT Bearer authentication
   - Automatically downloads OIDC metadata from Entra ID
   - Configures token validation parameters (issuer, audience, signature)
   - Sets up token validation middleware

2. **Token Validation Parameters** (automatic):
   - **Issuer**: Validates token is from your Entra ID tenant
   - **Audience**: Validates token is intended for your API (matches `Audience` config)
   - **Signature**: Validates token signature using Entra ID's public signing keys
   - **Expiration**: Validates token hasn't expired
   - **Not Before**: Validates token is currently valid

3. **`RequireAuthorization()`**: Marks endpoint as protected
   - Requests without valid token return 401 Unauthorized
   - Requests with invalid/expired token return 401 Unauthorized

### Adding CORS (Required for React to call API)

To allow the React app to call the API from a different origin, add CORS:

```csharp
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:3000")  // React dev server
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

app.UseCors();  // Enable CORS
app.UseAuthentication();
app.UseAuthorization();
```

**Production CORS Configuration:**

For production, specify exact origins:

```csharp
policy.WithOrigins("https://app.example.com", "https://www.example.com")
      .AllowAnyHeader()
      .AllowAnyMethod();
```

### Accessing User Claims

Once authenticated, you can access user information from the JWT token:

```csharp
app.MapGet("/me", (HttpContext context) =>
{
    var user = context.User;
    var userId = user.FindFirst("oid")?.Value;           // Object ID
    var username = user.FindFirst("preferred_username")?.Value;
    var email = user.FindFirst("email")?.Value;
    
    return new 
    { 
        UserId = userId, 
        Username = username, 
        Email = email 
    };
})
.RequireAuthorization();
```

**Common JWT Claims:**

- `oid`: Object ID (unique user identifier)
- `preferred_username`: User's UPN or email
- `name`: User's display name
- `email`: User's email address
- `scp`: Scopes granted (e.g., "access_as_user")
- `tid`: Tenant ID
- `iss`: Issuer (Entra ID)
- `aud`: Audience (your API)

### Validating Scopes

To ensure the access token has the required scope:

```csharp
app.MapGet("/secure-data", (HttpContext context) =>
{
    var scopeClaim = context.User.FindFirst("scp")?.Value;
    
    if (scopeClaim == null || !scopeClaim.Contains("access_as_user"))
    {
        return Results.Forbid();
    }
    
    return Results.Ok(new { Data = "Secure data here" });
})
.RequireAuthorization();
```

Alternatively, use policy-based authorization:

```csharp
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("RequireAccessAsUserScope", policy =>
        policy.RequireClaim("scp", "access_as_user"));
});

app.MapGet("/secure-data", () => { /* ... */ })
   .RequireAuthorization("RequireAccessAsUserScope");
```

## Running the Applications

### 1. Configure Application Settings

**React App (`msal-react-app/src/authConfig.js`):**

```javascript
export const msalConfig = {
  auth: {
    clientId: "{SPA_CLIENT_ID}",      // From Terraform output
    authority: "https://login.microsoftonline.com/{TENANT_ID}",
    redirectUri: "http://localhost:3000",
  },
  cache: {
    cacheLocation: "localStorage",
    storeAuthStateInCookie: false,
  },
};

export const loginRequest = {
  scopes: [
    "User.Read",
    "api://{API_CLIENT_ID}/access_as_user"  // Add your API scope
  ],
};
```

**.NET API (`net-api/MyApi/appsettings.json`):**

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "{TENANT_ID}",
    "ClientId": "{API_CLIENT_ID}",
    "Audience": "api://{API_CLIENT_ID}"
  }
}
```

Replace placeholders:
- `{SPA_CLIENT_ID}`: From `terraform output spa_app_client_id`
- `{API_CLIENT_ID}`: From `terraform output api_app_client_id`
- `{TENANT_ID}`: From Azure Portal → Entra ID → Overview

### 2. Start the .NET API

```bash
cd net-api/MyApi
dotnet restore
dotnet run
```

**Expected Output:**
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://localhost:5001
      Now listening on: http://localhost:5000
```

**Verify API is running:**
```bash
curl http://localhost:5000/weatherforecast
```

You should receive a 401 Unauthorized response (expected, as no auth token was provided).

### 3. Start the React App

In a new terminal:

```bash
cd msal-react-app
npm install
npm start
```

**Expected Output:**
```
Compiled successfully!

You can now view msal-react-app in the browser.

  Local:            http://localhost:3000
  On Your Network:  http://192.168.1.x:3000
```

The app should automatically open in your browser at `http://localhost:3000`.

### 4. Test Authentication Flow

1. **Navigate to** `http://localhost:3000`
2. **Click** "Sign In" button
3. **Redirected** to Microsoft Entra ID login page
4. **Enter** your credentials (user in your Azure AD tenant)
5. **Consent** to requested permissions (if first time)
6. **Redirected** back to app, now showing "Welcome, {username}"
7. **Test API call** (if implemented) to verify end-to-end flow

### 5. Verify Token in Browser

After signing in, open browser DevTools:

1. **Application** tab → **Local Storage** → `http://localhost:3000`
2. Look for keys starting with `msal.` - these contain tokens
3. Copy the value of a key containing `accesstoken`
4. Decode at [jwt.ms](https://jwt.ms) to inspect claims

**Expected Claims in Access Token:**
- `aud`: `api://{api-client-id}`
- `iss`: `https://login.microsoftonline.com/{tenant-id}/v2.0`
- `scp`: `access_as_user`
- `oid`: Your user's object ID

## Common Pitfalls and Troubleshooting

### 1. CORS Errors

**Symptom:**
```
Access to fetch at 'https://localhost:5001/weatherforecast' from origin 'http://localhost:3000' 
has been blocked by CORS policy
```

**Solution:**
- Ensure CORS is configured in .NET API `Program.cs`
- Add `app.UseCors()` before `app.UseAuthentication()`
- Verify React dev server origin is in allowed origins list

```csharp
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.WithOrigins("http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod());
});
```

### 2. Redirect URI Mismatch

**Symptom:**
```
AADSTS50011: The redirect URI 'http://localhost:3000' specified in the request 
does not match the redirect URIs configured for the application
```

**Solution:**
- Verify redirect URI in `authConfig.js` matches app registration
- Check Azure Portal → App registrations → my-spa-app → Authentication → Redirect URIs
- Ensure platform type is "Single-page application" (not "Web")
- Re-run `terraform apply` if configuration was changed

### 3. Invalid Audience

**Symptom:**
.NET API returns 401 Unauthorized even with a token. API logs show:
```
Microsoft.IdentityModel.Tokens.SecurityTokenInvalidAudienceException: 
IDX10214: Audience validation failed
```

**Solution:**
- Verify `Audience` in `appsettings.json` matches `api://{api-client-id}`
- Check access token's `aud` claim at [jwt.ms](https://jwt.ms)
- Ensure React app requests scope for your API: `api://{api-client-id}/access_as_user`

### 4. Admin Consent Not Granted

**Symptom:**
```
AADSTS65001: The user or administrator has not consented to use the application
```

**Solution:**
- Terraform should automatically grant admin consent
- Manually grant: Azure Portal → App registrations → my-spa-app → API permissions → Grant admin consent
- Verify service principal delegated permission grants exist:
  ```bash
  terraform state list | grep permission_grant
  ```

### 5. Token Expiration Issues

**Symptom:**
API calls fail intermittently with 401 after some time.

**Solution:**
- Use `acquireTokenSilent()` instead of using cached tokens directly
- MSAL automatically refreshes tokens when they're close to expiration
- Implement fallback to interactive token acquisition:
  ```javascript
  try {
    const response = await instance.acquireTokenSilent(tokenRequest);
  } catch (error) {
    if (error instanceof InteractionRequiredAuthError) {
      await instance.acquireTokenPopup(tokenRequest);
    }
  }
  ```

### 6. Terraform State Issues

**Symptom:**
```
Error: A resource with the ID "..." already exists
```

**Solution:**
- Resource was created outside of Terraform or state is out of sync
- Option 1: Import existing resource:
  ```bash
  terraform import azuread_application.app_name /applications/object-id
  ```
- Option 2: Delete and recreate:
  ```bash
  terraform destroy
  terraform apply
  ```

### 7. localhost vs 127.0.0.1

**Symptom:**
Login works, but redirect fails or CORS errors occur.

**Solution:**
- Always use `localhost` consistently (not `127.0.0.1`)
- Browser treats them as different origins
- Update all configurations to use same host:
  - React dev server: `http://localhost:3000`
  - Redirect URI: `http://localhost:3000`
  - CORS origin: `http://localhost:3000`

### 8. Browser Blocks Third-Party Cookies

**Symptom:**
Authentication fails in incognito/private mode or with strict cookie settings.

**Solution:**
- MSAL.js doesn't rely on third-party cookies with proper PKCE flow
- Ensure `storeAuthStateInCookie: false` in MSAL config
- Use `localStorage` for cache location
- If issues persist, test in a different browser

### 9. Missing Scopes in Token

**Symptom:**
Access token doesn't contain expected `scp` claim.

**Solution:**
- Verify scope is requested in `loginRequest` in React app
- Check scope is exposed in API app registration
- Ensure admin consent is granted for the scope
- Clear browser cache and re-authenticate

### 10. Terraform Provider Authentication Issues

**Symptom:**
```
Error: Unable to acquire a token: ...
```

**Solution:**
- Ensure Azure CLI is installed and authenticated:
  ```bash
  az login
  az account show
  ```
- Verify you have permissions to create app registrations
- Set subscription if needed:
  ```bash
  az account set --subscription "subscription-id"
  ```

### Debugging Tips

**Enable MSAL Logging (React):**
```javascript
const msalInstance = new PublicClientApplication({
  ...msalConfig,
  system: {
    loggerOptions: {
      loggerCallback: (level, message, containsPii) => {
        if (containsPii) return;
        console.log(message);
      },
      logLevel: LogLevel.Verbose
    }
  }
});
```

**Enable Detailed .NET Logging:**
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore.Authentication": "Debug",
      "Microsoft.Identity.Web": "Debug"
    }
  }
}
```

**Inspect JWT Tokens:**
- Copy token from browser DevTools → Local Storage
- Paste into [jwt.ms](https://jwt.ms) to decode and inspect claims
- Verify `aud`, `iss`, `scp`, and expiration (`exp`)

**Check Azure AD Sign-in Logs:**
- Navigate to Azure Portal → Entra ID → Sign-in logs
- Find your recent sign-ins
- Check for errors or failures
- Review conditional access policy impact

### Useful Resources

- **MSAL.js Documentation**: https://github.com/AzureAD/microsoft-authentication-library-for-js
- **Microsoft Identity Platform**: https://learn.microsoft.com/en-us/entra/identity-platform/
- **Microsoft.Identity.Web**: https://github.com/AzureAD/microsoft-identity-web
- **JWT Decoder**: https://jwt.ms
- **OAuth 2.0 Playground**: https://oauthdebugger.com/
- **Terraform Azure AD Provider**: https://registry.terraform.io/providers/hashicorp/azuread/latest/docs

---

## Summary

This project demonstrates a complete implementation of securing a React SPA and .NET API with Microsoft Entra ID:

1. **Infrastructure**: Terraform automates creation of app registrations and permissions
2. **Frontend**: React uses MSAL.js for user authentication and token acquisition
3. **Backend**: .NET API validates JWT tokens and enforces authorization
4. **Security**: OAuth 2.0 with PKCE ensures secure token exchange
5. **Integration**: End-to-end flow from user login to protected API access

By following this guide, you should have a fully functional authentication and authorization system using modern security best practices.