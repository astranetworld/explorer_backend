defmodule Explorer.Repo.Migrations.AddUniqueIndexToVerifier do
  use Ecto.Migration

  def change do
    create(
      unique_index(
        :block_verifiers_rewards,
        [:block_hash, :address_hash]
      )
    )
  end
end
