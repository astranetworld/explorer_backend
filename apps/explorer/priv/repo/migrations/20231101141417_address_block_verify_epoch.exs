defmodule Explorer.Repo.Migrations.AddressBlockVerifyEpoch do
  use Ecto.Migration

  def change do
    create table(:address_block_verify_epoch, primary_key: false) do
      add(:address_hash, :bytea,  null: false, primary_key: true)
      add(:epoch, :integer, null: false, primary_key: true)

      add(:verify_count, :integer, null: false)

      timestamps(null: false, type: :utc_datetime_usec)
    end
  end
end
