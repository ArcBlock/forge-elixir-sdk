defmodule ForgeSdk.Util.SocketData do
  @moduledoc """
  Encode / decode socket data transferred between forge and forge app. Use varint.
  """

  alias ForgeSdk.Util.Varint

  # see: https://github.com/tendermint/abci#socket-tsp
  @doc """
  decode a socket stream
  """
  @spec decode(binary(), module()) :: {list(map()), rest :: binary()}
  def decode(<<>>, _mod), do: {[], <<>>}

  def decode(data, mod) do
    case Varint.decode_zigzag(data) do
      :none ->
        {[], data}

      {length, rest} ->
        case rest do
          <<msg::binary-size(length), rest1::binary>> ->
            request = apply(mod, :decode, [msg])
            {rest_requests, rest2} = decode(rest1, mod)
            {[request | rest_requests], rest2}

          _ ->
            {[], data}
        end
    end
  end

  @spec decode_one(binary(), module()) :: {map(), binary()} | {nil, binary()}
  def decode_one(<<>>, _mod), do: {nil, <<>>}

  def decode_one(data, mod) do
    case Varint.decode_zigzag(data) do
      :none ->
        {nil, data}

      {length, rest} ->
        case rest do
          <<msg::binary-size(length), rest1::binary>> ->
            request = apply(mod, :decode, [msg])
            {request, rest1}

          _ ->
            {nil, data}
        end
    end
  end

  @doc """
  encode a socket stream
  """
  @spec encode(map(), module()) :: binary()
  def encode(data, mod) do
    response = apply(mod, :encode, [data])
    length = Varint.encode_zigzag(byte_size(response))
    <<length::binary, response::binary>>
  end
end
