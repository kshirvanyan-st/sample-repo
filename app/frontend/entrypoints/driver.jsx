import { createRoot } from "react-dom/client"
import App from "../driver/App"
import { setStrings } from "../driver/i18n"

const root = document.getElementById("driver-app")
setStrings(JSON.parse(root.dataset.strings))
createRoot(root).render(<App stateUrl={root.dataset.stateUrl} />)
