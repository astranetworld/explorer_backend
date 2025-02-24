defmodule Explorer.Repo.Migrations.CreateNewBlockMinnerRewards do
  use Ecto.Migration

  def change do
    create table(:block_minner_rewards, primary_key: false) do
      add(:address_hash, references(:addresses, column: :hash, on_delete: :delete_all, type: :bytea), null: false)
      #add(:address, :string, null: false)
      add(:block_hash, references(:blocks, column: :hash, on_delete: :delete_all, type: :bytea), null: false)
      add(:amount, :numeric, precision: 100, null: true)
      timestamps(null: false, type: :utc_datetime)
    end
    create(unique_index(:block_minner_rewards, [:address_hash, :block_hash]))
    create(index(:block_minner_rewards, :block_hash))
  end
end
