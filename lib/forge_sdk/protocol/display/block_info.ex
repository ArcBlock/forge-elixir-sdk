defimpl ForgeSdk.Display, for: ForgeAbi.BlockInfo do
  @moduledoc """
  Implementation of `Display` protocol for `BlockInfo`
  """
  use ForgeAbi.Unit

  alias ForgeSdk.Display

  def display(data, _expand? \\ false) do
    basic = Map.from_struct(data)
    version = Display.display(basic.version)

    Map.merge(basic, %{
      time: Display.display(basic.time),
      app_hash: Base.encode16(basic.app_hash || ""),
      proposer: basic.proposer,
      txs: Display.display(basic.txs),
      invalid_txs: Display.display(basic.invalid_txs),
      consensus_hash: Base.encode16(basic.consensus_hash || ""),
      data_hash: Base.encode16(basic.data_hash || ""),
      evidence_hash: Base.encode16(basic.evidence_hash || ""),
      last_commit_hash: Base.encode16(basic.last_commit_hash),
      last_results_hash: Base.encode16(basic.last_results_hash),
      next_validators_hash: Base.encode16(basic.next_validators_hash),
      validators_hash: Base.encode16(basic.validators_hash),
      version: %{app: version[:App], block: version[:Block]},
      last_block_id:
        Display.display(%{
          basic.last_block_id
          | hash: Base.encode16(basic.last_block_id.hash),
            parts_header: %{
              basic.last_block_id.parts_header
              | hash: Base.encode16(basic.last_block_id.parts_header.hash)
            }
        })
    })
  end
end

defimpl ForgeSdk.Display, for: ForgeAbi.BlockInfoSimple do
  @moduledoc """
  Implementation of `Display` protocol for `BlockInfoSimple`
  """
  use ForgeAbi.Unit

  alias ForgeSdk.Display

  def display(data, _expand? \\ false) do
    basic = Map.from_struct(data)
    version = Display.display(basic.version)

    Map.merge(basic, %{
      time: Display.display(basic.time),
      app_hash: Base.encode16(basic.app_hash || ""),
      proposer: basic.proposer,
      consensus_hash: Base.encode16(basic.consensus_hash || ""),
      data_hash: Base.encode16(basic.data_hash || ""),
      evidence_hash: Base.encode16(basic.evidence_hash || ""),
      last_commit_hash: Base.encode16(basic.last_commit_hash),
      last_results_hash: Base.encode16(basic.last_results_hash),
      next_validators_hash: Base.encode16(basic.next_validators_hash),
      validators_hash: Base.encode16(basic.validators_hash),
      version: %{app: version[:App], block: version[:Block]},
      last_block_id:
        Display.display(%{
          basic.last_block_id
          | hash: Base.encode16(basic.last_block_id.hash),
            parts_header: %{
              basic.last_block_id.parts_header
              | hash: Base.encode16(basic.last_block_id.parts_header.hash)
            }
        })
    })
  end
end
