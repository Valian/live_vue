defmodule LiveVue.SSR.ViteJS do
  @moduledoc false
  @behaviour LiveVue.SSR

  def render(name, props, slots) do
    data = Jason.encode!(%{name: name, props: props, slots: slots})
    url = ~c"http://127.0.0.1:5173/ssr_render"
    params = {url, [], ~c"application/json", data}

    case :httpc.request(:post, params, [], []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        body

      {:ok, {{_, 500, _}, _headers, body}} ->
        case Jason.decode(body) do
          {:ok, %{"error" => %{"message" => msg, "loc" => loc, "frame" => frame}}} ->
            {:error, "#{msg}\n#{loc["file"]}:#{loc["line"]}:#{loc["column"]}\n#{frame}"}

          _ ->
            {:error, "Unexpected Vite SSR response: 500 #{body}"}
        end

      {:ok, {{_, status, code}, _headers, _body}} ->
        {:error, "Unexpected Vite SSR response: #{status} #{code}"}

      {:error, {:failed_connect, [{:to_address, {url, port}}, {_, _, code}]}} ->
        {:error, "Unable to connect to Vite #{url}:#{port}: #{code}"}
    end
  end
end
