
const bodyParser = require('body-parser')

function liveVuePlugin(opts = {}) {
    const jsonMiddleware = bodyParser.json()
    return {
        name: 'live-vue',
        handleHotUpdate(payload) {
            // updates to these files will be handled by Phoenix reloader, not vite
            if(payload.file.match(/\.(heex|ex)$/)) return []
        },
        configureServer(server) {
            // Terminate the watcher when Phoenix quits
            // configureServer is only called in dev, so it's safe to use here
            process.stdin.on("close", () => process.exit(0));
            process.stdin.resume();
            
            // setup SSR endpoint /ssr_render
            const path = opts.path || "/ssr_render" 
            const entrypoint = opts.entrypoint || './js/server.js'
            server.middlewares.use(function fooMiddleware(req, res, next) {
            if (req.method == "POST" &&req.url.split("?", 1)[0] === path) {
                jsonMiddleware(req, res, async () => {
                    try {
                        const render = (await server.ssrLoadModule(entrypoint)).render
                        const html = await render(req.body.name, req.body.props, req.body.slots)
                        res.end(html)
                    } catch(e) {
                        server.ssrFixStacktrace(e)
                        res.statusCode = 500;
                        res.setHeader('Content-Type', 'application/json');
                        res.end(JSON.stringify({ error: e }));
                    }
                });
            } else {
                next();
            }
            });
        },
    }
}

module.exports = liveVuePlugin