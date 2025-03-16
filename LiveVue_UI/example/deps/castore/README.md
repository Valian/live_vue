# CAStore

[![CI badge](https://github.com/elixir-mint/castore/actions/workflows/ci.yml/badge.svg)](https://github.com/elixir-mint/castore/actions/workflows/ci.yml)
[![Documentation badge](https://img.shields.io/badge/Documentation-ff69b4)](https://hexdocs.pm/castore)
[![Hex.pm badge](https://img.shields.io/badge/Package%20on%20hex.pm-informational)](https://hex.pm/packages/castore)

Up-to-date CA certificate store for Elixir.

## Installation

In your `mix.exs`:

```elixir
def deps do
  [
    {:castore, "~> 1.0"}
  ]
end
```

Then, run `$ mix deps.get`.

## Usage

This is a micro-library whose only job is storing an up-to-date CA certificate store. The only provided function is `CAStore.file_path/0`, which returns the path of the CA certificate store file.

```elixir
CAStore.file_path()
#=> /Users/me/castore/_build/dev/lib/castore/priv/cacerts.pem"
```

See [the documentation](https://hexdocs.pm/castore).

## Updates

Every time there is an update to the CA certificate store, we'll release a new **patch version** of the library. For example, `1.0.12` → `1.0.13`.

## Contributing

If you want to locally update the CA certificate store file bundled with this library, run the `mix certdata` from the root of this library.

## License

Copyright 2018 Eric Meadows-Jönsson and Andrea Leopardi

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
