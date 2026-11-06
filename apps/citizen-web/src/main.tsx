import React from "react"
import ReactDOM from "react-dom/client"
import App from "./App"
import { CitizenRuntimeProvider } from "./runtime"
import "./index.css"

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <CitizenRuntimeProvider><App /></CitizenRuntimeProvider>
  </React.StrictMode>,
)
