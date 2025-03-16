# Plug.Cowboy

[![Hex.pm Version](https://img.shields.io/hexpm/v/plug_cowboy.svg)](https://hex.pm/packages/plug_cowboy)
[![Build Status](https://github.com/elixir-plug/plug_cowboy/workflows/CI/badge.svg)](https://github.com/elixir-plug/plug_cowboy/actions?query=workflow%3ACI)

A Plug Adapter for the Erlang [Cowboy](https://github.com/ninenines/cowboy
) web server.

## Installation

You can use `plug_cowboy` in your project by adding the dependency:

```elixir
def deps do
  [
    {:plug_cowboy, "~> 2.0"},
  ]
end
```

You can then start the adapter with:

```elixir
Plug.Cowboy.http MyPlug, []
```

## Supervised handlers

The `Plug.Cowboy` module can be started as part of a supervision tree like so:

```elixir
defmodule MyApp do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Plug.Cowboy, scheme: :http, plug: MyApp, port: 4040}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Contributing

We welcome everyone to contribute to Plug.Cowboy and help us tackle existing issues!

- Use the [issue tracker](https://github.com/elixir-plug/plug_cowboy/issues) for bug reports or feature requests.
- Open a [pull request](https://github.com/elixir-plug/plug_cowboy/pulls) when you are ready to contribute.
- Do not update the `CHANGELOG.md` when submitting a pull request.

## License

Plug.Cowboy source code is released under Apache License 2.0.
Check the [LICENSE](./LICENSE) file for more information.
