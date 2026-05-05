defmodule LiveVue.Patch do
  @moduledoc false

  @op_codes %{
    "add" => "a",
    "remove" => "d",
    "replace" => "r",
    "upsert" => "u",
    "limit" => "l"
  }

  @ops_by_code Map.new(@op_codes, fn {op, code} -> {code, op} end)

  def serialize(patches) do
    Enum.map_join(patches, "", &serialize_op/1)
  end

  def deserialize(""), do: []

  def deserialize(payload) when is_binary(payload) do
    payload
    |> parse_ops([])
    |> Enum.reverse()
  end

  defp serialize_op(%{op: "test", path: "", value: nonce}), do: "n#{nonce}"

  defp serialize_op(%{op: op, path: path, value: value}) do
    path = encode_path(path)
    "#{op_code(op)}#{byte_size(path)}:#{path}#{encode_value(value)}"
  end

  defp serialize_op(%{op: op, path: path}) do
    path = encode_path(path)
    "#{op_code(op)}#{byte_size(path)}:#{path}"
  end

  defp encode_path(""), do: ""

  defp encode_path("/" <> rest) do
    rest
    |> String.split("/")
    |> Enum.map_join(".", &String.replace(&1, ".", "~2"))
  end

  defp encode_value(nil), do: "z"
  defp encode_value(value) when is_boolean(value), do: "b#{if(value, do: 1, else: 0)}"

  defp encode_value(value) when is_number(value) do
    encoded = to_string(value)
    "n#{byte_size(encoded)}:#{encoded}"
  end

  defp encode_value(value) when is_binary(value), do: "s#{byte_size(value)}:#{value}"

  defp encode_value(value) do
    encoded =
      value
      |> Jason.encode!()
      |> Base.url_encode64(padding: false)

    "J#{byte_size(encoded)}:#{encoded}"
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

    if op in ["remove"] do
      parse_ops(rest, [[op, path] | acc])
    else
      {value, rest} = parse_value(rest)
      parse_ops(rest, [[op, path, value] | acc])
    end
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
    "/" <>
      (path
       |> String.split(".")
       |> Enum.map_join("/", &String.replace(&1, "~2", ".")))
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

  defp op_code(op), do: Map.fetch!(@op_codes, op)
  defp op_from_code(code), do: Map.fetch!(@ops_by_code, code)
end
