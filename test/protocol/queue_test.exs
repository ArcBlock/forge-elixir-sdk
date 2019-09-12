defmodule ForgeSdkTest.Queue do
  @moduledoc false
  use ExUnit.Case

  alias ForgeAbi.CircularQueue
  alias ForgeSdk.Queue
  alias Google.Protobuf.Any

  test "test init basic" do
    res = Queue.init(CircularQueue.new())
    assert res.type_url === ""
    assert res.max_items === 0
    assert res.circular === false
    assert res.fifo === false
    assert res.items === []
  end

  test "test init basic with opt" do
    res =
      Queue.init(CircularQueue.new(),
        type_url: "test",
        max_items: 3,
        circular: true,
        fifo: true,
        items: []
      )

    assert res.type_url === "test"
    assert res.max_items === 3
    assert res.circular === true
    assert res.fifo === true
    assert res.items === []
  end

  test "test add with different type_url" do
    queue = Queue.init(CircularQueue.new(), type_url: "test")
    res = Queue.add(queue, %{type_url: "test2", value: "1"})
    assert res.items === []
  end

  test "test add with same type_url" do
    item = Any.new(type_url: "test", value: "1")
    queue = Queue.init(CircularQueue.new(), type_url: "test")
    res = Queue.add(queue, %{type_url: "test", value: "1"})
    assert List.first(res.items) === item.value
  end

  test "test add and circular is false" do
    item_1 = Any.new(type_url: "test", value: "1")
    item_2 = Any.new(type_url: "test", value: "2")
    item_3 = Any.new(type_url: "test", value: "3")
    item_4 = Any.new(type_url: "test", value: "4")
    queue = Queue.init(CircularQueue.new(), type_url: "test", max_items: 3, circular: false)
    queue = Queue.add(queue, item_1)
    queue = Queue.add(queue, item_2)
    queue = Queue.add(queue, item_3)
    res = Queue.add(queue, item_4)
    assert res.items === [item_3.value, item_2.value, item_1.value]
  end

  test "test add and circular is false and max_items is 0" do
    item_1 = %{type_url: "test", value: "1"}
    item_2 = %{type_url: "test", value: "2"}
    item_3 = %{type_url: "test", value: "3"}
    item_4 = %{type_url: "test", value: "4"}
    queue = Queue.init(CircularQueue.new(), type_url: "test", max_items: 0, circular: false)
    queue = Queue.add(queue, item_1)
    queue = Queue.add(queue, item_2)
    queue = Queue.add(queue, item_3)
    res = Queue.add(queue, item_4)
    assert res.items === [item_4.value, item_3.value, item_2.value, item_1.value]
  end

  test "test add and circular is true and fifo is false" do
    item_1 = %{type_url: "test", value: "1"}
    item_2 = %{type_url: "test", value: "2"}
    item_3 = %{type_url: "test", value: "3"}
    item_4 = %{type_url: "test", value: "4"}
    queue = Queue.init(CircularQueue.new(), type_url: "test", max_items: 3, circular: true)
    queue = Queue.add(queue, item_1)
    queue = Queue.add(queue, item_2)
    queue = Queue.add(queue, item_3)
    res = Queue.add(queue, item_4)
    assert res.items === [item_4.value, item_3.value, item_2.value]
  end

  test "test add and circular is true and fifo is true" do
    item_1 = %{type_url: "test", value: "1"}
    item_2 = %{type_url: "test", value: "2"}
    item_3 = %{type_url: "test", value: "3"}
    item_4 = %{type_url: "test", value: "4"}

    queue =
      Queue.init(CircularQueue.new(), type_url: "test", max_items: 3, circular: true, fifo: true)

    queue = Queue.add(queue, item_1)
    queue = Queue.add(queue, item_2)
    queue = Queue.add(queue, item_3)
    res = Queue.add(queue, item_4)
    assert res.items === [item_2.value, item_3.value, item_4.value]
  end

  test "test remove and fifo is false" do
    item_1 = Any.new(type_url: "test", value: "1")
    item_2 = Any.new(type_url: "test", value: "2")
    item_3 = Any.new(type_url: "test", value: "3")
    queue = Queue.init(CircularQueue.new(), type_url: "test", max_items: 3, circular: true)
    queue = Queue.add(queue, item_1)
    queue = Queue.add(queue, item_2)
    queue = Queue.add(queue, item_3)
    res = Queue.remove(queue, :value, "1")
    assert res.items === [item_3.value, item_2.value]
  end

  test "test remove and fifo is true" do
    item_1 = %{type_url: "test", value: "1"}
    item_2 = %{type_url: "test", value: "2"}
    item_3 = %{type_url: "test", value: "3"}

    queue =
      Queue.init(CircularQueue.new(), type_url: "test", max_items: 3, circular: true, fifo: true)

    queue = Queue.add(queue, item_1)
    queue = Queue.add(queue, item_2)
    queue = Queue.add(queue, item_3)
    res = Queue.remove(queue, :value, "1")
    assert res.items === [item_2.value, item_3.value]
  end

  test "test pop and fifo is false" do
    item_1 = Any.new(type_url: "test", value: "1")
    item_2 = Any.new(type_url: "test", value: "2")
    item_3 = Any.new(type_url: "test", value: "3")

    queue = Queue.init(CircularQueue.new(), type_url: "test", max_items: 3, circular: true)
    queue = Queue.add(queue, item_1)
    queue = Queue.add(queue, item_2)
    queue = Queue.add(queue, item_3)
    {removed_item, res} = Queue.pop(queue)
    assert removed_item === item_3.value
    assert res.items === [item_2.value, item_1.value]
  end

  test "test pop and fifo is true" do
    item_1 = %{type_url: "test", value: "1"}
    item_2 = %{type_url: "test", value: "2"}
    item_3 = %{type_url: "test", value: "3"}

    queue =
      Queue.init(CircularQueue.new(), type_url: "test", max_items: 3, circular: true, fifo: true)

    queue = Queue.add(queue, item_1)
    queue = Queue.add(queue, item_2)
    queue = Queue.add(queue, item_3)
    {removed_item, res} = Queue.pop(queue)
    assert removed_item === item_1.value
    assert res.items === [item_2.value, item_3.value]
  end

  test "test iterate with one items" do
    item_1 = %{type_url: "test", value: "1"}
    queue = Queue.init(CircularQueue.new(), type_url: "test", max_items: 3, circular: true)
    queue = Queue.add(queue, item_1)
    res = queue.items
    assert res === [item_1.value]
  end

  test "test iterate with multiple items" do
    item_1 = Any.new(type_url: "test", value: "1")
    item_2 = Any.new(type_url: "test", value: "2")
    item_3 = Any.new(type_url: "test", value: "3")
    queue = Queue.init(CircularQueue.new(), type_url: "test", max_items: 3, circular: true)
    queue = Queue.add(queue, item_1)
    queue = Queue.add(queue, item_2)
    queue = Queue.add(queue, item_3)
    res = queue.items
    assert res === [item_3.value, item_2.value, item_1.value]
  end

  test "test full and max_items is 0" do
    item_1 = %{type_url: "test", value: 1}
    queue = Queue.init(CircularQueue.new(), type_url: "test", max_items: 0, circular: true)
    queue = Queue.add(queue, item_1)
    res = Queue.full?(queue)
    assert res === false
  end

  test "test full and max_items is not 0 " do
    item_1 = %{type_url: "test", value: 1}
    queue = Queue.init(CircularQueue.new(), type_url: "test", max_items: 1, circular: true)
    queue = Queue.add(queue, item_1)
    res = Queue.full?(queue)
    assert res === true
  end

  test "test size" do
    item_1 = %{type_url: "test", value: 1}
    queue = Queue.init(CircularQueue.new(), type_url: "test")
    queue = Queue.add(queue, item_1)
    res = Queue.size(queue)
    assert res === 1
  end

  test "test init with items and fifo is false" do
    item_1 = Any.new(type_url: "test", value: "1")
    item_2 = Any.new(type_url: "test", value: "2")
    item_3 = Any.new(type_url: "test", value: "3")
    item_4 = Any.new(type_url: "test", value: "4")

    res =
      Queue.init(CircularQueue.new(),
        type_url: "test",
        max_items: 3,
        circular: true,
        fifo: false,
        items: [item_1, item_2, item_3, item_4]
      )

    assert res.items === [item_4.value, item_3.value, item_2.value]
  end

  test "test init with items and fifo is true" do
    item_1 = %{type_url: "test", value: "1"}
    item_2 = %{type_url: "test", value: "2"}
    item_3 = %{type_url: "test", value: "3"}
    item_4 = %{type_url: "test", value: "4"}

    res =
      Queue.init(CircularQueue.new(),
        type_url: "test",
        max_items: 3,
        circular: true,
        fifo: true,
        items: [item_1, item_2, item_3, item_4]
      )

    assert res.items === [item_2.value, item_3.value, item_4.value]
  end

  test "test contains" do
    item_1 = %{type_url: "test", value: "1"}
    item_2 = %{type_url: "test", value: "2"}
    item_3 = %{type_url: "test", value: "3"}
    item_4 = %{type_url: "test_1", value: "2"}

    res =
      Queue.init(CircularQueue.new(),
        type_url: "test",
        max_items: 2,
        circular: true,
        fifo: true,
        items: [item_1, item_2]
      )

    assert Queue.contains?(res, item_1) == true
    assert Queue.contains?(res, item_2) == true
    assert Queue.contains?(res, item_3) == false
    assert Queue.contains?(res, item_4) == false
  end
end
