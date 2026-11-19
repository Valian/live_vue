# Browser suite for test/e2e. Run with `mix e2e.test`, or `MIX_ENV=e2e mix test` after
# `npm run e2e:build`. Starts the server of test/e2e/server.exs in this VM.
# The e2e env has no logger config: keep the server's request logs out of the test output.
Logger.configure(level: :warning)

Code.require_file("../test/e2e/server.exs", __DIR__)
Code.require_file("support/utils.ex", __DIR__)
Code.require_file("support/case.ex", __DIR__)

ExUnit.start(timeout: 30_000)
