defmodule Explorer.Chain.Block.Verifier do
  @moduledoc """
  Represents the total reward given to an address in a block.
  """
  require Logger

  use Explorer.Schema

  # alias Explorer.Chain.Block.Verifier
  alias Explorer.Chain.{Address, Block, Hash}
  # import Ecto.Query, only: [from: 2, preload: 3, subquery: 1, where: 3]
  # block_hash
  @required_attrs ~w(address_hash block_hash  public_key)a

  @typedoc """
  The static block given to the miner of a verifiers.

  * `:address` - block address
  * `:public_key` - key hash
  """

  @type t :: %__MODULE__{
          address: %Ecto.Association.NotLoaded{} | Address.t() | nil,
          address_hash: Address.hash(),
          block: %Ecto.Association.NotLoaded{} | Block.t() | nil,
          block_hash: Block.hash(),
          public_key: String.t() | nil
        }

  @primary_key false
  schema "block_verifiers_rewards" do
    field(:public_key, :string)
    belongs_to(:address,Address,foreign_key: :address_hash,references: :hash,type: Hash.Address)
    belongs_to(:block, Block, foreign_key: :block_hash, references: :hash, type: Hash.Full)
    timestamps()
  end

  def changeset(%__MODULE__{} = verifier, attrs) do
    # Logger.info("-----model-----#{inspect(verifier)}====");
    verifier
    # :block_hash
    |> cast(attrs, [:address_hash, :block_hash, :public_key])
    # :block_hash
    |> validate_required([:address_hash, :block_hash, :public_key])
    # |> foreign_key_constraint(:block_hash)
    # |> unique_constraint(:block_hash, name: :verifier_hash_to_block_hash)


    # |> assoc_constraint(:address_hash)
    # |> assoc_constraint(:block)
    # |> foreign_key_constraint(:block_hash)
    #  |> cast(attrs, [:block_range, :reward])
    #  |> validate_required([:block_range, :reward])
  end
end
