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
