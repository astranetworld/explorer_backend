defmodule Explorer.Chain.Block.MinnerReward do
  @moduledoc """
  Represents the total reward given to an address in a block.
  """

  use Explorer.Schema

  alias Explorer.Chain.Wei
  alias Explorer.Chain.{Address, Block, Hash}

  @required_attrs ~w(address_hash block_hash amount)a

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
          amount: Wei.t()
        }

  @primary_key false
  schema "block_minner_rewards" do
    #field(:address,:string)
    belongs_to(
      :address,
      Address,
      foreign_key: :address_hash,
      references: :hash,
      type: Hash.Address
    )
    field(:amount, Wei)
    belongs_to(
      :block,
      Block,
      foreign_key: :block_hash,
      references: :hash,
      type: Hash.Full
    )
    timestamps()
  end

  def changeset(%__MODULE__{} = minner_rewards, attrs) do
    minner_rewards
    |> cast(attrs, [:address_hash, :block_hash, :amount])
    |> validate_required([:address_hash, :block_hash, :amount])
  end
end
