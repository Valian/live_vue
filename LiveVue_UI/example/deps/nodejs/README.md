# NodeJS

[![Build Status](https://travis-ci.org/revelrylabs/elixir-nodejs.svg?branch=master)](https://travis-ci.org/revelrylabs/elixir-nodejs)
[![Hex.pm](https://img.shields.io/hexpm/dt/nodejs.svg)](https://hex.pm/packages/nodejs)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Coverage Status](https://opencov.prod.revelry.net/projects/14/badge.svg)](https://opencov.prod.revelry.net/projects/14)

Provides an Elixir API for calling Node.js functions.

## Documentation

The docs can
be found at [https://hexdocs.pm/nodejs](https://hexdocs.pm/nodejs).

## Prerequisites

- Elixir >= 1.7
- NodeJS >= 10

## Installation

```elixir
def deps do
  [
    {:nodejs, "~> 2.0"}
  ]
end
```

## Starting the service

Add `NodeJS` to your Supervisor as a child, pointing the required `path` option at the
directory containing your JavaScript modules.

```elixir
supervisor(NodeJS, [[path: "/node_app_root", pool_size: 4]])
```

### Calling JavaScript module functions with `NodeJS.call(module, args \\ [])`.

If the module exports a function directly, like this:

```javascript
module.exports = (x) => x
```

You can call it like this:

```elixir
NodeJS.call("echo", ["hello"]) #=> {:ok, "hello"}
```

There is also a `call!` form that throws on error instead of returning a tuple:

```elixir
NodeJS.call!("echo", ["hello"]) #=> "hello"
```

If the module exports an object with named functions like:

```javascript
exports.add = (a, b) => a + b
exports.sub = (a, b) => a - b
```

You can call them like this:

```elixir
NodeJS.call({"math", :add}, [1, 2]) # => {:ok, 3}
NodeJS.call({"math", :sub}, [1, 2]) # => {:ok, -1}
```

In order to cope with Unicode character it is necessary to specify the `binary` option:

```elixir
NodeJS.call("echo", ["’"], binary: true) # => {:ok, "’"}
```

### There Are Rules & Limitations (Unfortunately)

- Function arguments must be serializable to JSON.
- Return values must be serializable to JSON. (Objects with circular references will definitely fail.)
- Modules must be requested relative to the `path` that was given to the `Supervisor`.
  E.g., for a `path` of `/node_app_root` and a file `/node_app_root/foo/index.js` your module request should be for `"foo/index.js"` or `"foo/index"` or `"foo"`.

### Running the tests

  Since the test suite requires npm dependencies before you can run the tests you will first need to run

  ```bash
  cd test/js && npm install && cd ../..
  ```

  After that you should be able to run

  ```bash
  mix test
  ```

### Handling Callbacks and Promises  

You can see examples of using promises in the tests here:

https://github.com/revelrylabs/elixir-nodejs/blob/master/test/nodejs_test.exs#L125

and from the JavaScript code here:

```
module.exports = async function echo(x, delay = 1000) {
  return new Promise((resolve) => setTimeout(() => resolve(x), delay))
}
```

https://github.com/revelrylabs/elixir-nodejs/blob/master/test/js/slow-async-echo.js