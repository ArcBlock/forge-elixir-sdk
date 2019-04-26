defmodule ForgeSdk do
  @moduledoc """
  Public interfaces for ForgeSdk.
  """

  alias ForgeSdk.{Configuration.Helper, Display, File, Loader, Rpc, Util}

  # Transaction helper
  defdelegate account_migrate(itx, opts), to: Rpc
  # defdelegate consensus_upgrade(itx, opts), to: Rpc
  defdelegate consume_asset(itx, opts), to: Rpc
  defdelegate create_asset(itx, opts), to: Rpc
  defdelegate declare(itx, opts), to: Rpc
  defdelegate declare_file(itx, opts), to: Rpc
  defdelegate deploy_protocol(itx, opts), to: Rpc
  defdelegate exchange(itx, opts), to: Rpc
  defdelegate poke(itx, opts), to: Rpc
  defdelegate stake(itx, opts), to: Rpc
  # defdelegate sys_upgrade(itx, opts), to: Rpc
  defdelegate transfer(itx, opts), to: Rpc
  defdelegate update_asset(itx, opts), to: Rpc
  defdelegate upgrade_node(itx, opts), to: Rpc
  # defdelegate upgrade_task(itx, opts), to: Rpc

  # extended tx helper
  defdelegate stake_for_node(address, amount, opts), to: Rpc
  defdelegate checkin(opts), to: Rpc

  # RPC

  # chain related
  defdelegate get_chain_info(chan \\ nil), to: Rpc
  defdelegate get_node_info(chan \\ nil), to: Rpc
  defdelegate get_net_info(chan \\ nil), to: Rpc
  defdelegate get_validators_info(chan \\ nil), to: Rpc

  defdelegate create_tx(request, chan \\ nil), to: Rpc
  defdelegate multisig(request, chan \\ nil), to: Rpc
  defdelegate send_tx(request, chan \\ nil), to: Rpc
  defdelegate get_tx(requests, chan \\ nil), to: Rpc
  defdelegate get_unconfirmed_txs(request, chan \\ nil), to: Rpc
  defdelegate get_block(requests, chan \\ nil), to: Rpc
  defdelegate get_blocks(request, chan \\ nil), to: Rpc
  defdelegate search(request, chan \\ nil), to: Rpc
  defdelegate get_config(chan \\ nil), to: Rpc

  # wallet related
  defdelegate create_wallet(request, chan \\ nil), to: Rpc
  defdelegate load_wallet(request, chan \\ nil), to: Rpc
  defdelegate recover_wallet(request, chan \\ nil), to: Rpc
  defdelegate list_wallet(chan \\ nil), to: Rpc
  defdelegate remove_wallet(request, chan \\ nil), to: Rpc
  defdelegate declare_node(request, chan \\ nil), to: Rpc

  # state related
  defdelegate get_account_state(request, chan \\ nil), to: Rpc
  defdelegate get_asset_state(request, chan \\ nil), to: Rpc
  defdelegate get_forge_state(chan \\ nil), to: Rpc
  defdelegate get_protocol_state(request, chan \\ nil), to: Rpc
  defdelegate get_stake_state(request, chan \\ nil), to: Rpc

  # filesystem related
  defdelegate store_file(request, chan \\ nil), to: File
  defdelegate load_file(request, chan \\ nil), to: File
  defdelegate pin_file(request, chan \\ nil), to: Rpc

  # subscription related
  defdelegate subscribe(request, chan \\ nil, opts \\ []), to: Rpc
  defdelegate unsubscribe(request, chan \\ nil, opts \\ []), to: Rpc

  # extended
  defdelegate get_nonce(address, chan \\ nil, app_hash \\ ""), to: Rpc

  # display a data structure
  defdelegate display(data, expand? \\ false), to: Display

  # other
  defdelegate parse_config(name, file \\ ""), to: Util, as: :parse
  defdelegate find_config_file!, to: Util
  defdelegate load_config_file!(filename \\ nil), to: Util
  defdelegate gen_config(params), to: Util
  defdelegate get_env(key), to: Helper
  defdelegate put_env(key, value), to: Helper
  defdelegate get_chan, to: Util
  defdelegate datetime_to_proto(dt), to: Util
  defdelegate proto_to_datetime(ts), to: Util
  defdelegate update_config(forge_state), to: Util
  defdelegate update_type_url(forge_state), to: Loader
  defdelegate get_tx_protocols(forge_state), to: Loader

  # init sdk and handler registration
  defdelegate init(otp_app, app_hash \\ "", filename \\ nil), to: Util

  # stats
  defdelegate get_forge_stats(requests, chan \\ nil), to: Rpc
  defdelegate list_transactions(request, chan \\ nil), to: Rpc
  defdelegate list_assets(request, chan \\ nil), to: Rpc
  defdelegate list_stakes(request, chan \\ nil), to: Rpc
  defdelegate list_account(request, chan \\ nil), to: Rpc
  defdelegate list_top_accounts(request, chan \\ nil), to: Rpc
  defdelegate list_asset_transactions(request, chan \\ nil), to: Rpc
  defdelegate list_blocks(request, chan \\ nil), to: Rpc
  defdelegate get_health_status(request, chan \\ nil), to: Rpc
end
