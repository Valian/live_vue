const fs = require('node:fs/promises');
const path = require('path')
const readline = require('readline')

const WRITE_CHUNK_SIZE = parseInt(process.env.WRITE_CHUNK_SIZE, 10)
const NODE_PATHS = (process.env.NODE_PATH || '').split(path.delimiter).filter(Boolean)
const PREFIX = "__elixirnodejs__UOSBsDUP6bp9IF5__";

async function fileExists(file) {
  return await fs.access(file, fs.constants.R_OK).then(() => true).catch(() => false);
}

function requireModule(modulePath) {
  // When not running in production mode, refresh the cache on each call.
  if (process.env.NODE_ENV !== 'production') {
    delete require.cache[require.resolve(modulePath)]
  }

  return require(modulePath)
}

async function importModuleRespectingNodePath(modulePath) {
  // to be compatible with cjs require, we simulate resolution using NODE_PATH
  for(const nodePath of NODE_PATHS) {
    // Try to resolve the module in the current path
    const modulePathToTry = path.join(nodePath, modulePath)
    if (fileExists(modulePathToTry)) {
      // imports are cached. To bust that cache, add unique query string to module name
      // eg NodeJS.call({"esm-module.mjs?q=#{System.unique_integer()}", :fn})
      // it will leak memory, so I'm not doing it by default! 
      // see more: https://ar.al/2021/02/22/cache-busting-in-node.js-dynamic-esm-imports/#cache-invalidation-in-esm-with-dynamic-imports
      return await import(modulePathToTry)
    }
  }
  
  throw new Error(`Could not find module '${modulePath}'. Hint: File extensions are required in ESM. Tried ${NODE_PATHS.join(", ")}`)
}

function getAncestor(parent, [key, ...keys]) {
  if (typeof key === 'undefined') {
    return parent
  }

  return getAncestor(parent[key], keys)
}

async function getResponse(string) {
  try {
    const [[modulePath, ...keys], args, useImport] = JSON.parse(string)
    const importFn = useImport ? importModuleRespectingNodePath : requireModule
    const mod = await importFn(modulePath) 
    const fn = await getAncestor(mod, keys)
    if (!fn) throw new Error(`Could not find function '${keys.join(".")}' in module '${modulePath}'`)
    const returnValue = fn(...args)
    const result = returnValue instanceof Promise ? await returnValue : returnValue
    return JSON.stringify([true, result])
  } catch ({ message, stack }) {
    return JSON.stringify([false, `${message}\n${stack}`])
  }
}

async function onLine(string) {
  const buffer = Buffer.from(`${await getResponse(string)}\n`)

  // The function we called might have written something to stdout without starting a new line.
  // So we add one here and write the response after the prefix
  process.stdout.write("\n")
  process.stdout.write(PREFIX)
  for (let i = 0; i < buffer.length; i += WRITE_CHUNK_SIZE) {
    let chunk = buffer.slice(i, i + WRITE_CHUNK_SIZE)

    process.stdout.write(chunk)
  }
}

function startServer() {
  process.stdin.on('end', () => process.exit())

  const readLineInterface = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false,
  })

  readLineInterface.on('line', onLine)
}

module.exports = { startServer }

if (require.main === module) {
  startServer()
}
