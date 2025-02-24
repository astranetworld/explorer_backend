defmodule EthereumJSONRPC.AmazeToken.Verifiers do
  @moduledoc """
  List of Verifiers format as included in return from
  """

  alias EthereumJSONRPC.AmazeToken.Verifier

  @type elixir :: [Verifier.elixir()]
  @type params :: [Verifier.params()]
  @type t :: [Verifier.t()]

  @doc """
  Converts each entry in `elixir` to params used in `Explorer.Chain.Transaction.changeset/2`.
  """
  def elixir_to_params(elixir) when is_list(elixir) do
    Enum.map(elixir, &Verifier.elixir_to_params/1)
  end

  @doc """

  """
  def to_elixir(verifiers) when is_list(verifiers) do
    verifiers
    |> Enum.map(&Verifier.to_elixir/1)
    |> Enum.filter(&(!is_nil(&1)))
  end
end
