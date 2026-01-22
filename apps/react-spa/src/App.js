import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [health, setHealth] = useState(null);

  useEffect(() => {
    // Simple health check display
    fetch('/health')
      .then(res => res.json())
      .then(data => setHealth(data))
      .catch(err => console.error(err));
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>React SPA Application</h1>
        <p>Welcome to your Docker-deployed React application!</p>
        {health && (
          <div className="health-status">
            <p>Status: {health.status}</p>
          </div>
        )}
        <div className="features">
          <h2>Features</h2>
          <ul>
            <li>Docker containerized</li>
            <li>Nginx web server</li>
            <li>Traefik reverse proxy with SSL</li>
            <li>Health check endpoint</li>
            <li>Automatic deployment ready</li>
          </ul>
        </div>
      </header>
    </div>
  );
}

export default App;
