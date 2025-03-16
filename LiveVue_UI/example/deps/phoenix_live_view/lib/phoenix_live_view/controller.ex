defmodule Phoenix.LiveView.Controller do
  @moduledoc """
  Helpers for rendering LiveViews from a controller.
  """

  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @doc """
  Renders a live view from a Plug request and sends an HTML response
  from within a controller.

  It also automatically sets the `@live_module` assign with the value
  of the LiveView to be rendered.

  ## Options

  See `Phoenix.Component.live_render/3` for all supported options.

  ## Examples

      defmodule ThermostatController do
        use MyAppWeb, :controller

        # "use MyAppWeb, :controller" should import Phoenix.LiveView.Controller.
        # If it does not, you can either import it there or uncomment the line below:
        # import Phoenix.LiveView.Controller

        def show(conn, %{"id" => thermostat_id}) do
          live_render(conn, ThermostatLive, session: %{
            "thermostat_id" => thermostat_id,
            "current_user_id" => get_session(conn, :user_id)
          })
        end
      end

  """
  def live_render(%Plug.Conn{} = conn, view, opts \\ []) do
    case LiveView.Static.render(conn, view, opts) do
      {:ok, content, socket_assigns} ->
        conn
        |> Plug.Conn.fetch_query_params()
        |> ensure_format()
        |> Phoenix.Controller.put_view(LiveView.Static)
        |> Phoenix.Controller.render(
          :template,
          Map.merge(socket_assigns, %{content: content, live_module: view})
        )

      {:stop, %Socket{redirected: {:redirect, opts}} = socket} ->
        conn
        |> put_flash(LiveView.Utils.get_flash(socket))
        |> Phoenix.Controller.redirect(Map.to_list(opts))

      {:stop, %Socket{redirected: {:live, _, %{to: to}}} = socket} ->
        conn
        |> put_flash(LiveView.Utils.get_flash(socket))
        |> Plug.Conn.put_private(:phoenix_live_redirect, true)
        |> Phoenix.Controller.redirect(to: to)
    end
  end

  defp ensure_format(conn) do
    if Phoenix.Controller.get_format(conn) do
      conn
    else
      Phoenix.Controller.put_format(conn, "html")
    end
  end

  defp put_flash(conn, nil), do: conn

  defp put_flash(conn, flash),
    do: Enum.reduce(flash, conn, fn {k, v}, acc -> Phoenix.Controller.put_flash(acc, k, v) end)
end
