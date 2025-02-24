defmodule Explorer.Chain.Import.Runner.Block.MinnerRewards do
  @moduledoc """
  Bulk imports `t:Explorer.Chain.Block.SecondDegreeRelation.t/0`.
  """

  require Ecto.Query

  import Ecto.Query, only: [from: 2]

  alias Ecto.{Changeset, Multi, Repo}
  alias Explorer.Chain.{Block, Hash, Import}
  alias Explorer.Prometheus.Instrumenter
  require Logger

  @behaviour Import.Runner

  @timeout 60_000

  # @type imported :: [Hash.Full.t()]
  @type imported :: [Block.MinnerReward.t()]

  # @type imported :: [
  #         %{
  #           required(:address) => String.t(),
  #           # required(:block_hash) => Hash.Address.t()
  #           required(:public_key) => String.t()
  #         }
  #       ]

  @impl Import.Runner
  def ecto_schema_module, do: Block.MinnerReward

  @impl Import.Runner
  def option_key, do: :block_minner_rewards

  @impl Import.Runner
  def imported_table_row do
    %{
      value_type: "[#{ecto_schema_module()}.t()]",
      value_description: "List of `t:#{ecto_schema_module()}.t/0`s"
    }
  end

  @impl Import.Runner
  def run(multi, changes_list, %{timestamps: timestamps} = options) do
    insert_options =
      options
      |> Map.get(option_key(), %{})
      |> Map.take(~w(on_conflict timeout)a)
      |> Map.put_new(:timeout, @timeout)
      |> Map.put(:timestamps, timestamps)

    #Logger.error("-----verifier------import---")

    Multi.run(multi, :block_minner_rewards, fn repo, _ ->
      Instrumenter.block_import_stage_runner(
        fn -> insert(repo, changes_list, insert_options) end,
        :block_following,
        :minner_rewards,
        :block_minner_rewards
      )
    end)
  end

  @impl Import.Runner
  def timeout, do: @timeout

  @spec insert(Repo.t(), [map()], %{
          optional(:on_conflict) => Import.Runner.on_conflict(),
          required(:timeout) => timeout,
          required(:timestamps) => Import.timestamps()
        }) ::
          {:ok, [Block.MinnerReward.t()]} | {:error, [Changeset.t()]}
  # {:ok, nil | %{address: String.t(), public_key: String.t()}}
  # | {:error, [Changeset.t()]}
  defp insert(
         repo,
         changes_list,
         %{
           timeout: timeout,
           timestamps: timestamps
         } = options
       )
       when is_list(changes_list) do
    on_conflict = Map.get_lazy(options, :on_conflict, &default_on_conflict/0)

   # Logger.info("--changes_list--#{inspect(changes_list)}----")
    # Logger.info("--on_conflict--#{inspect(on_conflict)}----");
    # Enforce SeconDegreeRelation ShareLocks order (see docs: sharelocks.md)
    # block_hash
    # conflict_target: [:address, :public_key],
    #ordered_changes_list = Enum.sort_by(changes_list, &{&1.block_hash, &1.address})
    ordered_changes_list = Enum.sort_by(changes_list, &{&1.address_hash, &1.block_hash})
    # ordered_changes_list =
    #   changes_list
    #   |> Enum.sort_by(& &1.block_hash)

    Import.insert_changes_list(
      repo,
      ordered_changes_list,
      conflict_target: [:address_hash, :block_hash],
      #conflict_target: [:address],
      on_conflict: on_conflict,
      for: Block.MinnerReward,
      returning: [:address_hash, :block_hash, :amount],
      timeout: timeout,
      timestamps: timestamps
      # on_conflict: :nothing
    )
  end

  defp default_on_conflict do
    from(
      verifier in Block.MinnerReward,
      update: [
        set: [
          address_hash: fragment("EXCLUDED.address_hash"),
          # block_hash: fragment("EXCLUDED.block_hash"),#, EXCLUDED.block_hash,
          # public_key: fragment("EXCLUDED.public_key"),
          # Don't update `hash` as it is part of the primary key and used for the conflict target
          inserted_at: fragment("LEAST(?, EXCLUDED.inserted_at)", verifier.inserted_at),
          updated_at: fragment("GREATEST(?, EXCLUDED.updated_at)", verifier.updated_at)
        ]
      ],
      where:
        fragment("(EXCLUDED.address_hash) IS DISTINCT FROM (?)" ,verifier.address_hash)
        #fragment("(EXCLUDED.address,EXCLUDED.block_hash,EXCLUDED.public_key) IS DISTINCT FROM (?,?)" ,verifier.address,verifier.block_hash)
          #verifier.address,
           #verifier.block_hash,
        #EXCLUDED.address,
    )
  end
end
