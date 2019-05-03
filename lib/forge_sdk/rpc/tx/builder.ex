defmodule ForgeSdk.Tx.Builder do
  @moduledoc """
  Macro for building Tx RPC easily
  """
  alias ForgeSdk.Tx.Builder.Helper

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
            Helper.build(itx, opts)
          end

        options[:preprocessor] !== nil ->
          def unquote(type)(itx, opts) do
            [mod, fun] = unquote(options[:preprocessor])
            itx = apply(mod, fun, [itx, opts])
            Helper.build(itx, opts)
          end

        true ->
          def unquote(type)(itx, opts) do
            Helper.build(itx, opts)
          end
      end
    end
  end
end
