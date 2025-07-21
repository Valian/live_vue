import { Plugin } from "vite";
interface PluginOptions {
    path?: string;
    entrypoint?: string;
}
declare function liveVuePlugin(opts?: PluginOptions): Plugin;
export default liveVuePlugin;
