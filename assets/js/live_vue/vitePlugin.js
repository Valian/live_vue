
const bodyParser = require('body-parser')


function hotUpdateType(path) {
    if (path.endsWith('css')) return 'css-update';
    if (path.endsWith('js')) return 'js-update';
    return null
}

function liveVuePlugin(opts = {}) {
    const jsonMiddleware = bodyParser.json()
    return {
        name: 'live-vue',
        handleHotUpdate({file, modules, server, timestamp}) {
            if(file.match(/\.(heex|ex)$/)) {
                // if it's and .ex or .heex file, invalidate all related files so they'll be updated correctly
                const invalidatedModules = new Set()
                for (const mod of modules) {
                    server.moduleGraph.invalidateModule(
                        mod,
                        invalidatedModules,
                        timestamp,
                        true
                    )
                }

                const updates = Array.from(invalidatedModules)
                    .filter(m => hotUpdateType(m.file))
                    .map(m => ({
                        type: hotUpdateType(m.file),
                        path: m.url,
                        acceptedPath: m.url,
                        timestamp: timestamp,
                    }))

                // ask client to hot-reload updated modules
                server.ws.send({ type: 'update', updates: updates });

                // we handle the hot update ourselves
                return []
            }
        },
        configureServer(server) {
            // Terminate the watcher when Phoenix quits
            // configureServer is only called in dev, so it's safe to use here
            process.stdin.on("close", () => process.exit(0));
            process.stdin.resume();
            
            // setup SSR endpoint /ssr_render
            const path = opts.path || "/ssr_render" 
            const entrypoint = opts.entrypoint || './js/server.js'
            server.middlewares.use(function liveVueMiddleware(req, res, next) {
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