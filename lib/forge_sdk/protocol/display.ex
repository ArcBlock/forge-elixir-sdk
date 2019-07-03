defprotocol ForgeSdk.Display do
  @moduledoc """
  Display protocol. This is to show the data structure in various places.
  """
  @fallback_to_any true

  @type t :: ForgeSdk.Display.t()

  @doc """
  Convert a data structure to
  """
  @spec display(t(), boolean()) :: any()
  def display(data, expand? \\ false)
end

defimpl ForgeSdk.Display, for: Atom do
  @moduledoc """
  Implementation of `Display` protocol for `Atom`.
  """

  alias ForgeSdk.Display

  def display(nil, _expand?), do: nil

  def display(data, _expand?) do
    case is_boolean(data) do
      true -> data
      _ -> Atom.to_string(data)
    end
  end
end

defimpl ForgeSdk.Display, for: BitString do
  @moduledoc """
  Implementation of `Display` protocol for `Any`.
  """

  alias ForgeSdk.Display

  # TODO: need to figure out why this didn't work
  def display(data, _expand? \\ false) do
    case String.valid?(data) do
      true -> data
      _ -> Base.url_encode64(data, padding: false)
    end
  end
end

defimpl ForgeSdk.Display, for: List do
  @moduledoc """
  Implementation of `Display` protocol for `Any`.
  """

  alias ForgeSdk.Display

  def display(data, expand? \\ false) do
    Enum.map(data, &Display.display(&1, expand?))
  end
end

defimpl ForgeSdk.Display, for: Any do
  @moduledoc """
  Implementation of `Display` protocol for `Any`.
  """

  alias ForgeSdk.Display

  def display(data, expand? \\ false)

  def display(%{__struct__: _} = data, _expand?) do
    basic = Map.from_struct(data)

    Enum.reduce(basic, basic, fn {k, v}, acc ->
      cond do
        is_map(v) and Map.has_key?(v, :__struct__) -> Map.put(acc, k, Display.display(v))
        is_tuple(v) -> Map.put(acc, k, Display.display(v))
        is_list(v) -> Map.put(acc, k, Enum.map(v, &Display.display(&1)))
        true -> Map.put(acc, k, Display.display(v))
      end
    end)
  end

  def display(data, _expand?) when is_binary(data) do
    case String.valid?(data) do
      true -> data
      _ -> Base.url_encode64(data, padding: false)
    end
  end

  def display(data, _expand?), do: data
end
