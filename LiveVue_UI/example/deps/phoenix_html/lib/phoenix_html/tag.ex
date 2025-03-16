defmodule Phoenix.HTML.Tag do
  @moduledoc ~S"""
  Helpers related to producing HTML tags within templates.

  > Note: with the addition of the HEEx template engine to
  > Phoenix applications, the functions in this module have
  > lost a bit of relevance and must only be used in special
  > circumstances.
  >
  > Whenever possible, prefer to use the HEEx template engine
  > instead of the functions here. For example, instead of:
  >
  >     <%= content_tag :div, class: @class do %>
  >       Hello
  >     <% end %>
  >
  > Do:
  >
  >     <div class={@class}>
  >       Hello
  >     </div>

  > Note: the examples in this module use `safe_to_string/1`
  > imported from `Phoenix.HTML` for readability.
  """

  import Phoenix.HTML, except: [attributes_escape: 1]

  @csrf_param "_csrf_token"

  @doc ~S"""
  Creates an HTML tag with the given name and options.

      iex> safe_to_string tag(:br)
      "<br>"
      iex> safe_to_string tag(:input, type: "text", name: "user_id")
      "<input name=\"user_id\" type=\"text\">"

  ## Data attributes

  In order to add custom data attributes you need to pass
  a tuple containing :data atom and a keyword list
  with data attributes' names and values as the first element
  in the tag's attributes keyword list:

      iex> safe_to_string tag(:input, [data: [foo: "bar"], id: "some_id"])
      "<input data-foo=\"bar\" id=\"some_id\">"

  ## Boolean values

  In case an attribute contains a boolean value, its key
  is repeated when it is true, as expected in HTML, or
  the attribute is completely removed if it is false:

      iex> safe_to_string tag(:audio, autoplay: "autoplay")
      "<audio autoplay=\"autoplay\">"
      iex> safe_to_string tag(:audio, autoplay: true)
      "<audio autoplay>"
      iex> safe_to_string tag(:audio, autoplay: false)
      "<audio>"

  If you want the boolean attribute to be sent as is,
  you can explicitly convert it to a string before.
  """
  def tag(name), do: tag(name, [])

  def tag(name, attrs) when is_list(attrs) do
    {:safe, [?<, to_string(name), sorted_attrs(attrs), ?>]}
  end

  @doc ~S"""
  Creates an HTML tag with given name, content, and attributes.

  See `Phoenix.HTML.Tag.tag/2` for more information and examples.

      iex> safe_to_string content_tag(:p, "Hello")
      "<p>Hello</p>"

      iex> safe_to_string content_tag(:p, "<Hello>", class: "test")
      "<p class=\"test\">&lt;Hello&gt;</p>"

      iex> safe_to_string(content_tag :p, class: "test" do
      ...>   "Hello"
      ...> end)
      "<p class=\"test\">Hello</p>"

      iex> safe_to_string content_tag(:option, "Display Value", [{:data, [foo: "bar"]}, value: "value"])
      "<option data-foo=\"bar\" value=\"value\">Display Value</option>"

  """
  def content_tag(name, do: block) do
    content_tag(name, block, [])
  end

  def content_tag(name, content) do
    content_tag(name, content, [])
  end

  def content_tag(name, attrs, do: block) when is_list(attrs) do
    content_tag(name, block, attrs)
  end

  def content_tag(name, content, attrs) when is_list(attrs) do
    name = to_string(name)
    {:safe, escaped} = html_escape(content)
    {:safe, [?<, name, sorted_attrs(attrs), ?>, escaped, ?<, ?/, name, ?>]}
  end

  defp sorted_attrs(attrs) when is_list(attrs),
    do: attrs |> Enum.sort() |> attributes_escape() |> elem(1)

  defp sorted_attrs(attrs),
    do: attrs |> Enum.to_list() |> sorted_attrs()

  @doc false
  @deprecated "Use Phoenix.HTML.attributes_escape/1 instead"
  defdelegate attributes_escape(attrs), to: Phoenix.HTML

  @doc ~S"""
  Generates a form tag.

  This function generates the `<form>` tag without its closing part.
  Check `form_tag/3` for generating an enclosing tag.

  ## Examples

      form_tag("/hello")
      <form action="/hello" method="post">

      form_tag("/hello", method: :get)
      <form action="/hello" method="get">

  ## Options

    * `:method` - the HTTP method. If the method is not "get" nor "post",
      an input tag with name `_method` is generated along-side the form tag.
      Defaults to "post".

    * `:multipart` - when true, sets enctype to "multipart/form-data".
      Required when uploading files

    * `:csrf_token` - for "post" requests, the form tag will automatically
      include an input tag with name `_csrf_token`. When set to false, this
      is disabled

  All other options are passed to the underlying HTML tag.

  ## CSRF Protection

  By default, CSRF tokens are generated through `Plug.CSRFProtection`.
  """
  def form_tag(action, opts \\ [])

  def form_tag(action, do: block) do
    form_tag(action, [], do: block)
  end

  def form_tag(action, opts) when is_list(opts) do
    {:safe, method} = html_escape(Keyword.get(opts, :method, "post"))

    {extra, opts} =
      case method do
        "get" ->
          {"", opts}

        "post" ->
          {csrf, opts} = csrf_form_tag(action, opts)
          {csrf, Keyword.put(opts, :method, "post")}

        _ ->
          {csrf, opts} = csrf_form_tag(action, opts)

          {[
             ~s'<input name="_method" type="hidden" hidden value="',
             to_string(method),
             ~s'">' | csrf
           ], Keyword.put(opts, :method, "post")}
      end

    opts =
      case Keyword.pop(opts, :multipart, false) do
        {false, opts} -> opts
        {true, opts} -> Keyword.put(opts, :enctype, "multipart/form-data")
      end

    html_escape([tag(:form, [action: action] ++ opts), raw(extra)])
  end

  @doc """
  Generates a form tag with the given contents.

  ## Examples

      form_tag("/hello", method: "get") do
        "Hello"
      end
      <form action="/hello" method="get">...Hello...</form>

  """
  def form_tag(action, options, do: block) do
    html_escape([form_tag(action, options), block, raw("</form>")])
  end

  defp csrf_form_tag(to, opts) do
    case Keyword.pop(opts, :csrf_token, true) do
      {csrf_token, opts} when is_binary(csrf_token) ->
        {[~s'<input name="#{@csrf_param}" type="hidden" hidden value="', csrf_token, ~s'">'],
         opts}

      {true, opts} ->
        csrf_token = csrf_token_value(to)

        {[~s'<input name="#{@csrf_param}" type="hidden" hidden value="', csrf_token, ~s'">'],
         opts}

      {false, opts} ->
        {[], opts}
    end
  end

  @doc """
  Returns the `csrf_token` value to be used by forms, meta tags, etc.

  By default, CSRF tokens are generated through `Plug.CSRFProtection`
  which is capable of generating a separate token per host. Therefore
  it is recommended to pass the `URI` of the destination as argument.
  If none is given `%URI{host: nil}` is used, which implies a local
  request is being done.
  """
  def csrf_token_value(to \\ %URI{host: nil}) do
    {mod, fun, args} = Application.fetch_env!(:phoenix_html, :csrf_token_reader)
    apply(mod, fun, [to | args])
  end

  @doc """
  Generates a meta tag with CSRF information.

  Additional options to the tag can be given.
  """
  def csrf_meta_tag(opts \\ []) do
    tag(:meta, [name: "csrf-token", content: csrf_token_value()] ++ opts)
  end

  @doc """
  Generates a hidden input tag with a CSRF token.

  This could be used when writing a form without the use of tag
  helpers like `form_tag/3` or `form_for/4`, while maintaining
  CSRF protection.

  The `to` argument should be the same as the form action.

  ## Example

      <form action="/login" method="POST">
        <%= csrf_input_tag("/login") %>

        etc.
      </form>

  Additional options to the tag can be given.
  """
  def csrf_input_tag(to, opts \\ []) do
    csrf_token = csrf_token_value(to)
    tag(:input, [type: "hidden", name: @csrf_param, value: csrf_token] ++ opts)
  end

  @doc """
  Generates an img tag with a src.

  ## Examples

      img_tag(user.photo_path)
      <img src="/photo.png">

      img_tag(user.photo, class: "image")
      <img src="/smile.png" class="image">

  To generate a path to an image hosted in your application "priv/static",
  with the `@conn` endpoint, use `static_path/2` to get a URL with
  cache control parameters:

      img_tag(Routes.static_path(@conn, "/logo.png"))
      <img src="/logo-123456.png?vsn=d">

  For responsive images, pass a map, list or string through `:srcset`.

      img_tag("/logo.png", srcset: %{"/logo.png" => "1x", "/logo-2x.png" => "2x"})
      <img src="/logo.png" srcset="/logo.png 1x, /logo-2x.png 2x">

      img_tag("/logo.png", srcset: ["/logo.png", {"/logo-2x.png", "2x"}])
      <img src="/logo.png" srcset="/logo.png, /logo-2x.png 2x">

  """
  def img_tag(src, opts \\ []) do
    opts =
      case Keyword.pop(opts, :srcset) do
        {nil, opts} -> opts
        {srcset, opts} -> [srcset: stringify_srcset(srcset)] ++ opts
      end

    tag(:img, Keyword.put_new(opts, :src, src))
  end

  defp stringify_srcset(srcset) when is_map(srcset) or is_list(srcset) do
    Enum.map_join(srcset, ", ", fn
      {src, descriptor} -> "#{src} #{descriptor}"
      default -> default
    end)
  end

  defp stringify_srcset(srcset) when is_binary(srcset),
    do: srcset
end
