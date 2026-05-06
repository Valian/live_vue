defmodule LiveVue.Patch do
  @moduledoc """
  Encodes LiveVue patch operations into the compact wire format used by
  `data-props-diff` and `data-streams-diff`.

  The payload is a concatenated sequence of operations. Dynamic text fields are
  byte-length-prefixed, so paths and values can contain delimiters without extra
  escaping.

  Operation codes:

  | Code | Operation |
  | --- | --- |
  | `a` | `add` |
  | `d` | `remove` |
  | `r` | `replace` |
  | `u` | `upsert` |
  | `l` | `limit` |
  | `n` | nonce marker, ignored while decoding |

  Normal operations use:

  ```text
  <op><path_byte_len>:<path><value>
  ```

  `remove` omits `<value>`. The nonce marker uses `n<digits>` and exists only
  to force LiveView to send a changed attribute.

  Value tags:

  | Tag | Value |
  | --- | --- |
  | `z` | `nil` |
  | `b0`, `b1` | booleans |
  | `n<len>:<number>` | number |
  | `s<len>:<utf8 string>` | string |
  | `J<len>:<caret-encoded JSON>` | maps, lists, and complex values |

  Paths are transported as JSON Pointer strings unchanged.
  """

  @doc """
  Serializes patch maps into a compact binary payload.

  Expected patch shapes are `%{op: op, path: path, value: value}`,
  `%{op: "remove", path: path}`, and `%{op: "test", path: "", value: nonce}`.
  The nonce test operation is encoded as a marker and is not returned by
  `deserialize/1`.
  """
  def serialize(patches) do
    :erlang.iolist_to_binary(for patch <- patches, do: serialize_op(patch))
  end

  @doc """
  Encodes a JSON value for safe, compact HTML attribute transport.

  The value is encoded with Jason's default JSON escaping, then JSON quote
  characters are replaced with `^`. Literal `~` and `^` characters are escaped
  as `~~` and `~^`, so the transform is reversible by `decode_object/1`.
  """
  def encode_object(value) do
    value
    |> Jason.encode!()
    |> String.replace("~", "~~")
    |> String.replace("^", "~^")
    |> String.replace("\"", "^")
  end

  @doc false
  def decode_object(value) when is_binary(value) do
    value
    |> String.replace(~r/~~|~\^|\^/, fn
      "~~" -> "~"
      "~^" -> "^"
      "^" -> "\""
    end)
    |> Jason.decode!()
  end

  @doc """
  Deserializes a compact patch payload into list-shaped operations.

  Returns `[]` for an empty payload. Decoded operations are shaped as
  `[op, path]` for `remove` and `[op, path, value]` for all value-bearing
  operations. Nonce markers are skipped.
  """
  def deserialize(""), do: []

  def deserialize(payload) when is_binary(payload) do
    payload
    |> parse_ops([])
    |> Enum.reverse()
  end

  defp serialize_op(%{op: "test", path: "", value: nonce}), do: ["n", to_string(nonce)]

  defp serialize_op(%{op: op, path: path, value: value}) do
    path = encode_path(path)
    [op_code(op), Integer.to_string(byte_size(path)), ?:, path, encode_value(value)]
  end

  defp serialize_op(%{op: op, path: path}) do
    path = encode_path(path)
    [op_code(op), Integer.to_string(byte_size(path)), ?:, path]
  end

  defp encode_path(path), do: path

  defp encode_value(nil), do: "z"
  defp encode_value(true), do: "b1"
  defp encode_value(false), do: "b0"

  defp encode_value(value) when is_number(value) do
    encoded = to_string(value)
    ["n", Integer.to_string(byte_size(encoded)), ?:, encoded]
  end

  defp encode_value(value) when is_binary(value), do: ["s", Integer.to_string(byte_size(value)), ?:, value]

  defp encode_value(value) do
    encoded = encode_object(value)
    ["J", Integer.to_string(byte_size(encoded)), ?:, encoded]
  end

  defp parse_ops("", acc), do: acc

  defp parse_ops("n" <> rest, acc) do
    {_nonce, rest} = take_digits(rest)
    parse_ops(rest, acc)
  end

  defp parse_ops(<<code::binary-size(1), rest::binary>>, acc) do
    {path_length, rest} = take_length(rest)
    <<path::binary-size(path_length), rest::binary>> = rest
    op = op_from_code(code)
    parse_op(op, path, rest, acc)
  end

  defp parse_op("remove", path, rest, acc), do: parse_ops(rest, [["remove", path] | acc])

  defp parse_op(op, path, rest, acc) do
    {value, rest} = parse_value(rest)
    parse_ops(rest, [[op, path, value] | acc])
  end

  defp parse_value("z" <> rest), do: {nil, rest}
  defp parse_value("b1" <> rest), do: {true, rest}
  defp parse_value("b0" <> rest), do: {false, rest}

  defp parse_value(<<tag::binary-size(1), rest::binary>>) when tag in ["n", "s", "J"] do
    {length, rest} = take_length(rest)
    <<encoded::binary-size(length), rest::binary>> = rest

    value =
      case tag do
        "n" -> parse_number(encoded)
        "s" -> encoded
        "J" -> decode_object(encoded)
      end

    {value, rest}
  end

  defp parse_number(value) do
    case Integer.parse(value) do
      {integer, ""} ->
        integer

      _ ->
        {float, ""} = Float.parse(value)
        float
    end
  end

  defp take_length(payload) do
    {digits, ":" <> rest} = take_digits(payload)
    {String.to_integer(digits), rest}
  end

  defp take_digits(payload), do: take_digits(payload, "")

  defp take_digits(<<char, rest::binary>>, acc) when char in ?0..?9 do
    take_digits(rest, <<acc::binary, char>>)
  end

  defp take_digits(rest, acc), do: {acc, rest}

  defp op_code("add"), do: "a"
  defp op_code("remove"), do: "d"
  defp op_code("replace"), do: "r"
  defp op_code("upsert"), do: "u"
  defp op_code("limit"), do: "l"

  defp op_from_code("a"), do: "add"
  defp op_from_code("d"), do: "remove"
  defp op_from_code("r"), do: "replace"
  defp op_from_code("u"), do: "upsert"
  defp op_from_code("l"), do: "limit"
end
