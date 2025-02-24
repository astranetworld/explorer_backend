defmodule Explorer.Repo.Migrations.AddUniqueIndexDropToVerifier do
  use Ecto.Migration

  def change do
    drop_if_exists(
      index(:block_verifiers_rewards, [:block_hash, :address_hash],
        name: "block_verifiers_rewards_block_hash_address_hash_index"
      )
    )
  end
end
