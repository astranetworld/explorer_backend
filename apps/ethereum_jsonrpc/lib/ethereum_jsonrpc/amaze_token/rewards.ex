defmodule EthereumJSONRPC.AmazeToken.Rewards do
  @moduledoc """
  List of Rewards format as included in return from
  """

  alias EthereumJSONRPC.AmazeToken.Reward

  @type elixir :: [Reward.elixir()]
  @type params :: [Reward.params()]
  @type t :: [Reward.t()]

  @doc """
  Converts each entry in `elixir` to params used in `Explorer.Chain.Transaction.changeset/2`.
  """
  def elixir_to_params(elixir) when is_list(elixir) do
    Enum.map(elixir, &Reward.elixir_to_params/1)
  end

  @doc """

  """
  def to_elixir(rewards) when is_list(rewards) do
    rewards
    |> Enum.map(&Reward.to_elixir/1)
    |> Enum.filter(&(!is_nil(&1)))
  end
end
