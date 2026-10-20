import React from "react";
import ReactDOM from "react-dom/client";
import "./glass.css";
import App from "@/App";
import { initBridge } from "@/lib/client";

console.log("[Melyar] Booting UI...");
initBridge();

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
