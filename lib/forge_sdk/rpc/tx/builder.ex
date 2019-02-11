defmodule ForgeSdk.Rpc.Tx.Builder do
  @moduledoc """
  Macro for building Tx RPC easily
  """
  alias ForgeSdk.Rpc.Tx.Helper

  defmacro tx(type, options \\ []) do
    build(type, options)
  end

  defp build(type, options) do
    quote bind_quoted: [
            type: type,
            options: options
          ] do
      # credo:disable-for-lines:11
      cond do
        options[:multisig] == true ->
          def unquote(type)(itx, opts) do
            opts = Keyword.put(opts, :send, :nosend)
            Helper.build(unquote(type), itx, opts)
          end

        true ->
          def unquote(type)(itx, opts) do
            Helper.build(unquote(type), itx, opts)
          end
      end
    end
  end
end
