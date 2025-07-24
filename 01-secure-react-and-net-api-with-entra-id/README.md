# Secure react app and .net api with EntraID


## React-app

1. Prerequisites

- Node.js and npm installed
- Microsoft Entra ID tenant (via https://entra.microsoft.com)
- An App Registration in Entra ID

2. Create react app and install msal

```bash
npx create-react-app msal-react-app
cd msal-react-app
npm install @azure/msal-browser @azure/msal-react
```

3. Configure MSAL
Create a file: src/authConfig.js
```js
export const msalConfig = {
  auth: {
    clientId: "YOUR_CLIENT_ID", // From App Registration
    authority: "https://login.microsoftonline.com/YOUR_TENANT_ID", // or 'common' for multi-tenant
    redirectUri: "http://localhost:3000",
  },
  cache: {
    cacheLocation: "localStorage",
    storeAuthStateInCookie: false,
  },
};

export const loginRequest = {
  scopes: ["User.Read"], // Or custom API scopes
};
```

4. Initialize MSAL in the App
Update src/index.js:
```js
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { PublicClientApplication } from "@azure/msal-browser";
import { MsalProvider } from "@azure/msal-react";
import { msalConfig } from "./authConfig";

const msalInstance = new PublicClientApplication(msalConfig);

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(
  <MsalProvider instance={msalInstance}>
    <App />
  </MsalProvider>
);

5. Add Login / Logout / Profile UI

Update src/App.js:
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

## .NET API