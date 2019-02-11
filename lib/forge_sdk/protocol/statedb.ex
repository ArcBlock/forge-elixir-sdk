defprotocol ForgeSdk.StateDb do
  @moduledoc """
  StateDb protocol for interact with kv store
  """
  alias ForgeSdk.StateDb

  @type t :: StateDb.t()

  alias ForgeSdk.State

  @doc """
  Open a database for write/read
  """
  @spec open(t()) :: {:ok, map()} | {:error, term()}
  def open(handler)

  @doc """
  Close the database
  """
  @spec close(t()) :: :ok
  def close(handler)

  @doc """
  Retrieve the state from an address
  """
  @spec get(t(), binary()) :: State.t() | nil
  def get(handler, address)

  @doc """
  Retrieve the state from an address
  """
  @spec get(t(), binary(), binary()) :: State.t() | nil
  def get(handler, address, app_hash)

  @doc """
  Retrieve the raw state (not final) from an address, used internally for migration. No cache is needed.
  """
  @spec get_raw(t(), binary()) :: map() | binary() | nil
  def get_raw(handler, address)

  @doc """
  Check if a key exists in db
  """
  @spec has?(t(), binary()) :: boolean()
  def has?(handler, address)

  @doc """
  Check if a key exists in db
  """
  @spec has?(t(), binary(), binary()) :: boolean()
  def has?(handler, address, app_hash)

  @doc """
  Put the state into to address in the db. This will lead to a change of root_hash.
  """
  @spec put(t(), binary(), State.t()) :: {:ok, t()} | {:error, term()}
  def put(handler, address, data)

  @doc """
  Put the raw state into to address in the db. This will lead to a change of root_hash.
  """
  @spec put_raw(t(), binary(), binary()) :: {:ok, t()} | {:error, term()}
  def put_raw(handler, address, data)

  @doc """
  When a block is committed, record the last block and the app hash for that block. Then return the app hash.
  """
  @spec commit_block(t(), non_neg_integer()) :: binary()
  def commit_block(handler, height)

  @doc """
  Retrieve the last block height and the app_hash of the states db for a given height
  """
  @spec get_info(t(), non_neg_integer()) :: %{
          last_block: non_neg_integer(),
          app_hash: binary()
        }
  def get_info(handler, height \\ 0)

  @doc """
  Travel to different app hash (or block height). The returned db handler could be used to retrieve old state from the db.
  """
  @spec travel(t(), non_neg_integer() | binary() | nil) :: t()
  def travel(handler, height_or_hash)
end
