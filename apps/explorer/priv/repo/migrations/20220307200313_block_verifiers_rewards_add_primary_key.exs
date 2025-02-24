defmodule Explorer.Repo.Migrations.CreateNewBlockVerifiersRewardsAddPrimary do
  use Ecto.Migration

  def change do
    drop(
      unique_index(
        :block_verifiers_rewards,
        ~w(block_hash address_hash)a
      )
    )

    alter table(:block_verifiers_rewards) do
      modify(:block_hash, :bytea, null: false, primary_key: true)
      modify(:address_hash, :bytea, null: false, primary_key: true)
    end
  end

  # def change do
  #   drop(
  #     unique_index(
  #       :block_verifiers_rewards,
  #       ~w(address)a
  #     )
  #   )
  # def up do
  #   # Don't use `modify` as it requires restating the whole column description
  #   execute("ALTER TABLE block_verifiers_rewards ADD PRIMARY KEY (block_hash,address)")
  # end

  # def down do
  #   execute("ALTER TABLE block_verifiers_rewards DROP CONSTRAIN block_verifiers_rewards_pkey")
  # end

    # alter table(:block_verifiers_rewards) do
    #   modify(:address, :bytea, null: false, primary_key: true)
    # end
end
