import components from "../vue"
import { getRender, loadManifest } from "live_vue/server"

// present only in prod build. Returns empty obj if doesn't exist
// used to render preload links
const manifest = loadManifest("../priv/static/.vite/ssr-manifest.json")
export const render = getRender(components, manifest)
