defmodule Indexer.Transform.Amc.AddressVerifyDaily do
  @moduledoc """
  Extracts `Explorer.Chain.Amc.AddressVerifyDaily` params from other schema's params.
  """

  import EthereumJSONRPC, only: [integer_to_quantity: 1, json_rpc: 2, quantity_to_integer: 1, request: 1]

  def params_set(%{verifiers_params: verifiers_params_list, blocks: blocks}) do

    verifiers_daily_params_list =
      Enum.reduce(verifiers_params_list, [], fn verifiers_params, acc ->
        address_hash = Map.get(verifiers_params, :address_hash)
        block_number = Map.get(verifiers_params, :block_number)

        epoch = number_to_epoch(block_number)

        [%{address_hash: address_hash, epoch: epoch, verify_count: 1} | acc]
      end)
      |> Enum.reverse()

    verifiers_daily_params_list
  end
  
  defp number_to_epoch(block_number) do
    beijing_block = Application.get_all_env(:indexer)[Indexer.Fetcher.Amc][:beijing_block]
    epoch_length = Application.get_all_env(:indexer)[Indexer.Fetcher.Amc][:apos_epoch]

    adjusted_number = block_number - beijing_block + 1
    div(adjusted_number - 1, epoch_length) + 1
  end
end
