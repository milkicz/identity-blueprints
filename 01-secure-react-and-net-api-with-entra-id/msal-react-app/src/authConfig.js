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
