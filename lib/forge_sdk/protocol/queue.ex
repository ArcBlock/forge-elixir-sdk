defprotocol ForgeSdk.Queue do
  @moduledoc """
  Queue protocol.
  """

  alias Google.Protobuf.Any

  @type t :: ForgeSdk.Queue.t()

  @doc """
  Initialize a queue.
  """
  @spec init(t(), Keyword.t()) :: t()
  def init(queue, opts \\ [])

  @doc """
  Add an item into the queue.
  """
  @spec add(t(), Any.t()) :: t()
  def add(queue, item)

  @doc """
  Get the first matched item from the queue and remove it from the queue based on fifo.
  """
  @spec remove(t(), atom(), binary()) :: t()
  def remove(queue, key, value)

  @doc """
  Remove an item from the queue, return a tuple including a removed item and a queue.
  """
  @spec pop(t()) :: {Any.t(), t()}
  def pop(queue)

  @doc """
  Check if the queue is full.
  """
  @spec full?(t()) :: boolean()
  def full?(queue)

  @doc """
  Return the length of the queue.
  """
  @spec size(t()) :: non_neg_integer()
  def size(queue)
end

defimpl ForgeSdk.Queue, for: ForgeAbi.CircularQueue do
  @moduledoc """
  Implementation of `Queue` protocol for `CircularQueue`.
  """

  alias ForgeAbi.CircularQueue

  alias Google.Protobuf.Any

  @type t :: CircularQueue.t()

  @doc """
  Initialize a queue based on the parameters of the queue, the parameters of the queue can be passed from opts.
  """
  @spec init(t(), Keyword.t()) :: t()
  def init(_queue, opts \\ []) do
    queue =
      CircularQueue.new(
        type_url: opts[:type_url] || "",
        max_items: opts[:max_items] || 0,
        circular: opts[:circular] || false,
        fifo: opts[:fifo] || false
      )

    init_items(queue, opts[:items] || [])
  end

  @doc """
  Add an item into the queue based on the parameters of the queue. If item exists, we don't add it into the queue.
  """
  @spec add(t(), map()) :: t()
  def add(queue, nil), do: queue

  def add(queue, %{type_url: item_type_url, value: new_item}) do
    %{type_url: queue_type_url, circular: circular, items: items} = queue

    if find_item(items, new_item) === nil do
      case {queue_type_url == item_type_url, full?(queue), circular} do
        {false, _, _} -> queue
        {true, true, false} -> queue
        {true, false, _} -> add_item(queue, new_item)
        {true, true, true} -> replace_item(queue, new_item)
      end
    else
      queue
    end
  end

  @doc """
  Get the first matched item from the queue and remove it from the queue based on fifo field.
  """
  @spec remove(t(), atom(), any()) :: t()
  def remove(queue, nil, _), do: queue

  def remove(%{fifo: true, items: items} = queue, _key, value) do
    Map.put(queue, :items, List.delete(items, find_item(items, value)))
  end

  def remove(%{fifo: false, items: items} = queue, _key, value) do
    reversed_items = Enum.reverse(items)

    result_items =
      reversed_items
      |> List.delete(find_item(reversed_items, value))
      |> Enum.reverse()

    Map.put(queue, :items, result_items)
  end

  @doc """
  Remove an item from the queue.
  """
  @spec pop(t()) :: {Any.t(), t()}
  def pop(%{items: [first | rest]} = queue) do
    {first, Map.put(queue, :items, rest)}
  end

  @doc """
  Check if the queue is full.
  """
  @spec full?(t()) :: boolean()
  def full?(%{max_items: 0}), do: false

  def full?(%{max_items: max_items, items: items}) do
    max_items <= length(items)
  end

  @doc """
  Return the length of the queue.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%{items: items}), do: length(items)

  # private function

  defp init_items(queue, items) do
    Enum.reduce(items, queue, &add(&2, &1))
  end

  defp add_item(%{fifo: true, items: items} = queue, item) do
    Map.put(queue, :items, items ++ [item])
  end

  defp add_item(%{fifo: false, items: items} = queue, item) do
    Map.put(queue, :items, [item | items])
  end

  defp drop_item(%{fifo: true, items: items} = queue) do
    Map.put(queue, :items, tl(items))
  end

  defp drop_item(%{fifo: false, items: items} = queue) do
    head =
      items
      |> Enum.reverse()
      |> tl()
      |> Enum.reverse()

    Map.put(queue, :items, head)
  end

  defp replace_item(queue, item) do
    queue
    |> drop_item()
    |> add_item(item)
  end

  defp find_item(items, searched_item) do
    Enum.find(items, fn item -> item == searched_item end)
  end
end

defimpl Enumerable, for: ForgeAbi.CircularQueue do
  def count(queue), do: {:ok, Enum.count(queue.items)}
  def find(queue, fun), do: Enum.find(queue.items, fun)
  def member?(queue, item_any), do: {:ok, Enum.member?(queue.items, item_any.value)}

  def slice(queue),
    do: {:ok, Enum.count(queue), &Enumerable.List.slice(queue.items, &1, &2)}

  def reduce(queue, acc, fun), do: reduce_list(queue.items, acc, fun)

  defp reduce_list(_, {:halt, acc}, _fun), do: {:halted, acc}
  defp reduce_list(list, {:suspend, acc}, fun), do: {:suspended, acc, &reduce_list(list, &1, fun)}
  defp reduce_list([], {:cont, acc}, _fun), do: {:done, acc}
  defp reduce_list([h | t], {:cont, acc}, fun), do: reduce_list(t, fun.(h, acc), fun)
end
