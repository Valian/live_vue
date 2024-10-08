defmodule LiveVue.SSR.ViteJS do
  @moduledoc """
  Implements SSR by making a POST request to `http://{:vite_host}/ssr_render`.

  `ssr_render` is implemented as a Vite plugin. You have to add it to the `vite.config.js` plugins section.

  ```javascript
  import liveVuePlugin from "live_vue/vitePlugin"

  {
    publicDir: "static",
    plugins: [vue(), liveVuePlugin()],
    // ...
  }
  ```
  """
  @behaviour LiveVue.SSR

  def render(name, props, slots) do
    data = Jason.encode!(%{name: name, props: props, slots: slots})
    url = vite_path("/ssr_render")
    params = {String.to_charlist(url), [], ~c"application/json", data}

    case :httpc.request(:post, params, [], []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        :erlang.list_to_binary(body)

      {:ok, {{_, 500, _}, _headers, body}} ->
        case Jason.decode(body) do
          {:ok, %{"error" => %{"message" => msg, "loc" => loc, "frame" => frame}}} ->
            {:error, "#{msg}\n#{loc["file"]}:#{loc["line"]}:#{loc["column"]}\n#{frame}"}

          {:ok, %{"error" => %{"stack" => stack}}} ->
            {:error, stack}

          _ ->
            {:error, "Unexpected Vite SSR response: 500 #{body}"}
        end

      {:ok, {{_, status, code}, _headers, _body}} ->
        {:error, "Unexpected Vite SSR response: #{status} #{code}"}

      {:error, {:failed_connect, [{:to_address, {url, port}}, {_, _, code}]}} ->
        {:error, "Unable to connect to Vite #{url}:#{port}: #{code}"}
    end
  end

  @doc """
  A handy utility returning path relative to Vite JS host.
  """
  def vite_path(path) do
    case Application.get_env(:live_vue, :vite_host) do
      nil ->
        message = """
        Vite.js host is not configured. Please add the following to config/dev.ex

        config :live_vue, vite_host: "http://localhost:5173"

        and ensure vite.js is running
        """

        raise %LiveVue.SSR.NotConfigured{message: message}

      host ->
        # we get rid of assets prefix since for vite /assets is root
        Path.join(host, path)
    end
  end
end
