# The server is shared with the ExUnit port in test/e2e_pw.
Code.require_file("server.exs", __DIR__)

Process.register(self(), :e2e_helper)

IO.puts("Starting e2e server on port #{LiveVue.E2E.Endpoint.config(:http)[:port]}")

if not IEx.started?() do
  spawn(fn ->
    IO.read(:stdio, :line)
    send(:e2e_helper, :halt)
  end)

  receive do
    :halt -> :ok
  end
end
