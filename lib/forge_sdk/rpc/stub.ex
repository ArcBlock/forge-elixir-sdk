defmodule ForgeSdk.Rpc.Stub do
  @moduledoc """
  Aggregate all RPCs
  """

  defdelegate send_tx(chan, req, opts \\ []), to: ForgeAbi.ChainRpc.Stub
  defdelegate get_tx(chan, opts \\ []), to: ForgeAbi.ChainRpc.Stub
  defdelegate get_unconfirmed_txs(chan, req, opts \\ []), to: ForgeAbi.ChainRpc.Stub
  defdelegate get_block(chan, opts \\ []), to: ForgeAbi.ChainRpc.Stub
  defdelegate get_blocks(chan, req, opts \\ []), to: ForgeAbi.ChainRpc.Stub
  defdelegate get_chain_info(chan, req, opts \\ []), to: ForgeAbi.ChainRpc.Stub
  defdelegate get_node_info(chan, req, opts \\ []), to: ForgeAbi.ChainRpc.Stub
  defdelegate search(chan, req, opts \\ []), to: ForgeAbi.ChainRpc.Stub
  defdelegate get_net_info(chan, req, opts \\ []), to: ForgeAbi.ChainRpc.Stub
  defdelegate get_validators_info(chan, req, opts \\ []), to: ForgeAbi.ChainRpc.Stub
  defdelegate get_config(chan, req, opts \\ []), to: ForgeAbi.ChainRpc.Stub

  # wallet rpc
  defdelegate declare_node(chan, req, opts \\ []), to: ForgeAbi.WalletRpc.Stub

  # state rpc
  defdelegate get_account_state(chan, opts \\ []), to: ForgeAbi.StateRpc.Stub
  defdelegate get_asset_state(chan, opts \\ []), to: ForgeAbi.StateRpc.Stub
  defdelegate get_forge_state(chan, req, opts \\ []), to: ForgeAbi.StateRpc.Stub
  defdelegate get_swap_state(chan, opts \\ []), to: ForgeAbi.StateRpc.Stub
  defdelegate get_delegate_state(chan, opts \\ []), to: ForgeAbi.StateRpc.Stub

  # event rpc
  defdelegate subscribe(chan, req, opts \\ []), to: ForgeAbi.EventRpc.Stub
  defdelegate unsubscribe(chan, req, opts \\ []), to: ForgeAbi.EventRpc.Stub

  # stats rpc
  defdelegate get_forge_stats(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
  defdelegate list_transactions(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
  defdelegate list_assets(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
  defdelegate list_stakes(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
  defdelegate list_account(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
  defdelegate list_top_accounts(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
  defdelegate list_asset_transactions(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
  defdelegate list_blocks(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
  defdelegate list_swap(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
  defdelegate get_swap_statistics(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
  defdelegate get_health_status(chan, req, opts \\ []), to: ForgeAbi.StatsRpc.Stub
end
