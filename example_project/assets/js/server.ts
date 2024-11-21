import { getRender, loadManifest } from "live_vue/server"
import app from "../vue"

// present only in prod build. Returns empty obj if doesn't exist
// used to render preload links
const manifest = loadManifest("../priv/vue/.vite/ssr-manifest.json")
export const render = getRender(app, manifest)
