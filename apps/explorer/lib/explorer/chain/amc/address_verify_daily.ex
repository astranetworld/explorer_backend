defmodule Explorer.Chain.Amc.AddressVerifyDaily do
  @moduledoc """
  Count of verified blocks of `t:Explorer.Chain.Address.t/0` at one epoch.
  This table is used to display verify history chart.
  """

  use Explorer.Schema

  alias Explorer.Chain.{Address, Hash}
  alias Explorer.Chain.Amc.AddressVerifyDaily

  @required_fields ~w(address_hash epoch verify_count)a

  @typedoc """
   * `address` - the `t:Explorer.Chain.Address.t/0`.
   * `address_hash` - foreign key for `address`.
   * `verify_count` - Count of verified blocks of `t:Explorer.Chain.Address.t/0` during the epoch.
   * `inserted_at` - When the first verified block was first inserted into the database.
   * `updated_at` - When the last verified block was last updated.
  """
  @type t :: %__MODULE__{
          address: %Ecto.Association.NotLoaded{} | Address.t(),
          address_hash: Hash.Address.t(),
          epoch: non_neg_integer(),
          verify_count: non_neg_integer() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key false
  schema "address_block_verify_epoch" do
    field(:epoch, :integer)
    field(:verify_count, :integer)

    belongs_to(:address, Address, foreign_key: :address_hash, references: :hash, type: Hash.Address)

    timestamps()
  end

  def changeset(_, params) when is_nil(params), do: :ignore

  def changeset(%__MODULE__{} = addressVerifyDaily, params) when not is_nil(params) do
    addressVerifyDaily
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:epoch, name: :address_block_verify_epoch_address_hash_epoch_index)
  end
end
