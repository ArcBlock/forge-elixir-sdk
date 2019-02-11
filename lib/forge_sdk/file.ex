defmodule ForgeSdk.File do
  @moduledoc """
  Convenience functions for file api.
  """

  alias ForgeAbi.{RequestLoadFile, RequestStoreFile}
  alias ForgeSdk.Rpc
  alias GRPC.Channel

  @chunk_size 1400

  @doc """
  Chunk the file and delegate the rest to Rpc.store_file/2.
  """
  @spec store_file(
          [path: String.t()]
          | RequestStoreFile.t()
          | [RequestStoreFile.t()]
          | Keyword.t()
          | [Keyword.t()],
          Channel.t() | nil
        ) :: String.t() | {:error, term()}
  def store_file(request, chan \\ nil)

  def store_file([path: path], chan) do
    File.stream!(path, [], @chunk_size)
    |> Stream.map(&[chunk: &1])
    |> store_file(chan)
  end

  def store_file(request, chan) do
    Rpc.store_file(request, chan)
  end

  @doc """
  """
  @spec load_file(RequestLoadFile.t() | Keyword.t(), Channel.t() | nil) ::
          binary() | {:error, term()}
  def load_file(request, chan \\ nil) do
    case Rpc.load_file(request, chan) do
      {:error, reason} -> {:error, reason}
      [error: reason] -> {:error, reason}
      data when is_list(data) -> Enum.reduce(data, <<>>, &<<&2::binary, &1::binary>>)
    end
  end
end
