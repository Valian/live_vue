defmodule LiveVue.Patch do
  @moduledoc false

  def serialize(patches) do
    :erlang.iolist_to_binary(for patch <- patches, do: serialize_op(patch))
  end

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

  defp encode_path(""), do: ""

  defp encode_path("/" <> rest) do
    encode_path(rest, [])
  end

  defp encode_path(<<>>, acc), do: acc |> :lists.reverse() |> :erlang.iolist_to_binary()
  defp encode_path(<<?/, rest::binary>>, acc), do: encode_path(rest, [?. | acc])
  defp encode_path(<<?., rest::binary>>, acc), do: encode_path(rest, ["~2" | acc])
  defp encode_path(<<char, rest::binary>>, acc), do: encode_path(rest, [char | acc])

  defp encode_value(nil), do: "z"
  defp encode_value(true), do: "b1"
  defp encode_value(false), do: "b0"

  defp encode_value(value) when is_number(value) do
    encoded = to_string(value)
    ["n", Integer.to_string(byte_size(encoded)), ?:, encoded]
  end

  defp encode_value(value) when is_binary(value), do: ["s", Integer.to_string(byte_size(value)), ?:, value]

  defp encode_value(value) do
    encoded =
      value
      |> Jason.encode!()
      |> Base.url_encode64(padding: false)

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
    path = decode_path(path)

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
        "J" -> encoded |> Base.url_decode64!(padding: false) |> Jason.decode!()
      end

    {value, rest}
  end

  defp decode_path(""), do: ""

  defp decode_path(path) do
    :erlang.iolist_to_binary([?/ | decode_path(path, [])])
  end

  defp decode_path(<<>>, acc), do: :lists.reverse(acc)
  defp decode_path(<<?., rest::binary>>, acc), do: decode_path(rest, [?/ | acc])
  defp decode_path(<<?~, ?2, rest::binary>>, acc), do: decode_path(rest, [?. | acc])
  defp decode_path(<<char, rest::binary>>, acc), do: decode_path(rest, [char | acc])

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
