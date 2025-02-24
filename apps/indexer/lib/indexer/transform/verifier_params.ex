defmodule Indexer.Transform.VerifierParams do
  @moduledoc """
  Helper functions to parse addresses from mint transfers.

  When a network receives a mint coin, we can identify it using the `bridge_hash` in the first_topic.
  Then we need to fetch the `from` and `to` address since there is no transaction or internal
  transaction for it. Otherwise, those address may not be indexed.
  """

  @bridge_hash "0x3c798bbcf33115b42c728b8504cff11dd58736e9fa789f1cda2738db7d696b2a"

  @doc """
  Parses logs to find mint transfers.

  """
  def parse(blocks) do
    verifiers1 =
      blocks
      |> Enum.filter(&(&1.hash !== nil ))
      |> Enum.map(&parse_params/1)

    %{verifiers_params_set: verifiers1}
  end

  defp parse_params(%{hash: hash, number: number})
       when not is_nil(hash) do
    %{
      block_hash: hash,
      # from_address_hash: truncate_address_hash(third_topic),
      block_number: number
    }
  end

  # defp truncate_hash("0x" <> hash) do
  #   "0x#{hash}"
  # end

  # def params_set(%{} = import_options) do
  #   Enum.reduce(import_options, MapSet.new(), &reducer/1)
  # end


  def reducer(%{verifiers_params: verifiers_params}, acc) when is_list(verifiers_params) do
    verifiers_params
    |> Enum.into(acc, fn
      %{address_hash: address_hash, block_number: block_number}
      when is_binary(address_hash) and is_integer(block_number) ->
        %{address_hash: address_hash, block_number: block_number}
    end)
    |> Enum.reject(fn val -> is_nil(val) end)
    |> MapSet.new()
  end
end
