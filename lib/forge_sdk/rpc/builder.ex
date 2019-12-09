defmodule ForgeSdk.Rpc.Builder do
  @moduledoc """
  Macro for building RPC easily
  """
  alias ForgeSdk.Rpc.Helper
  alias ForgeSdk.Util

  defmacro rpc(service, options, contents \\ []) do
    compile(service, options, contents)
  end

  # credo:disable-for-lines:55
  defp compile(service, options, contents) do
    {body, options} =
      cond do
        Keyword.has_key?(contents, :do) ->
          {contents[:do], options}

        Keyword.has_key?(options, :do) ->
          Keyword.pop(options, :do)

        true ->
          raise ArgumentError, message: "expected :do to be given as option"
      end

    {service_name, service} =
      case options[:service] do
        nil -> {service, service}
        v -> {service, v}
      end

    mod = to_request_mod(service)

    quote bind_quoted: [
            mod: mod,
            service_name: service_name,
            service: service,
            options: options,
            body: Macro.escape(body, unquote: true)
          ] do
      default_opts = options[:opts] || []

      cond do
        options[:request_stream] == true ->
          def unquote(service_name)(reqs, name \\ "", opts \\ []) do
            conn = Util.get_conn(name)
            reqs = Helper.to_req(reqs, unquote(mod))
            fun = fn var!(res) -> unquote(body) end
            opts = Keyword.merge(unquote(default_opts), opts)
            Helper.send_stream(unquote(service), conn, reqs, opts, fun)
          end

        options[:response_stream] == true and options[:no_params] == true ->
          def unquote(service_name)(name \\ "", opts \\ []) do
            conn = Util.get_conn(name)
            req = apply(unquote(mod), :new, [])
            fun = fn var!(res) -> unquote(body) end
            opts = Keyword.merge(unquote(default_opts), opts)
            Helper.send(unquote(service), conn, req, opts, fun)
          end

        options[:response_stream] == true ->
          def unquote(service_name)(req, name \\ "", opts \\ []) do
            conn = Util.get_conn(name)
            req = Helper.to_req(req, unquote(mod))
            fun = fn var!(res) -> unquote(body) end
            opts = Keyword.merge(unquote(default_opts), opts)
            Helper.send(unquote(service), conn, req, opts, fun)
          end

        options[:no_params] == true ->
          def unquote(service_name)(name \\ "", opts \\ []) do
            conn = Util.get_conn(name)
            req = apply(unquote(mod), :new, [])
            fun = fn var!(res) -> unquote(body) end
            opts = Keyword.merge(unquote(default_opts), opts)
            Helper.send(unquote(service), conn, req, opts, fun)
          end

        true ->
          def unquote(service_name)(req, name \\ "", opts \\ []) do
            conn = Util.get_conn(name)
            req = Helper.to_req(req, unquote(mod))
            fun = fn var!(res) -> unquote(body) end
            opts = Keyword.merge(unquote(default_opts), opts)
            Helper.send(unquote(service), conn, req, opts, fun)
          end
      end
    end
  end

  defp to_request_mod(service) do
    name =
      service
      |> Atom.to_string()
      |> Recase.to_pascal()

    Module.concat(ForgeAbi, "Request#{name}")
  end

  # defp to_args(data) do
  #   data
  #   |> Map.keys()
  #   |> List.delete(:__struct__)
  #   |> Enum.map(&Macro.var(&1, __MODULE__))
  # end
end
