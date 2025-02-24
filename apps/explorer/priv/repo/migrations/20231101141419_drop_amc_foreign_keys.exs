# cspell:ignore fkey
defmodule Explorer.Repo.Migrations.DropRestAddressForeignKeys do
  use Ecto.Migration

  def change do
    drop_if_exists(constraint(:block_verifiers_rewards, :block_verifiers_rewards_address_hash_fkey))
    drop_if_exists(constraint(:block_verifiers_rewards, :block_verifiers_rewards_block_hash_fkey))
    drop_if_exists(constraint(:block_minner_rewards, :block_minner_rewards_address_hash_fkey))
    drop_if_exists(constraint(:block_minner_rewards, :block_minner_rewards_block_hash_fkey))
  end
end
