defmodule Explorer.Chain.Import.Runner.Amc.AddressVerifyDaily do
  @moduledoc """
  Bulk imports `t:Explorer.Chain.Address.CoinBalancesDaily.t/0`.
  """

  require Ecto.Query

  import Ecto.Query, only: [from: 2]

  alias Ecto.{Changeset, Multi, Repo}
  alias Explorer.Chain.Amc.AddressVerifyDaily
  alias Explorer.Chain.{Hash, Import, Wei}
  alias Explorer.Prometheus.Instrumenter

  require Logger

  @behaviour Import.Runner

  # milliseconds
  @timeout 60_000

  @type imported :: [AddressVerifyDaily.t()]

#  @type imported :: [
#                      %{required(:address_hash) => Hash.Address.t(), required(:epoch) => non_neg_integer(), required(:verify_count) => non_neg_integer()}
#                    ]

  @impl Import.Runner
  def ecto_schema_module, do: AddressVerifyDaily

  @impl Import.Runner
  def option_key, do: :address_block_verify_epoch

  @impl Import.Runner
  def imported_table_row do
    %{
      value_type: "[%{address_hash: Explorer.Chain.Hash.t(), epoch: non_neg_integer(), verify_count: non_neg_integer()}]",
      value_description: "List of  maps of the `t:#{ecto_schema_module()}.t/0` `address_hash` and `epoch` and `verify_count`"
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

    #Logger.error("-----AddressVerifyDaily------import---")

    Multi.run(multi, :address_block_verify_epoch, fn repo, _ ->
      Instrumenter.block_import_stage_runner(
        fn -> insert(repo, changes_list, insert_options) end,
        :block_following,
        :address_verify_daily,
        :address_block_verify_epoch
      )
    end)
  end

  @impl Import.Runner
  def timeout, do: @timeout

  @spec insert(
          Repo.t(),
          [
            %{
              required(:address_hash) => Hash.Address.t(),
              required(:epoch) => non_neg_integer(),
              required(:verify_count) => non_neg_integer()
            }
          ],
          %{
            optional(:on_conflict) => Import.Runner.on_conflict(),
            required(:timeout) => timeout,
            required(:timestamps) => Import.timestamps()
          }
        ) ::
          {:ok, [%{required(:address_hash) => Hash.Address.t(), required(:epoch) => non_neg_integer(), required(:verify_count) => non_neg_integer()}]}
          | {:error, [Changeset.t()]}
  defp insert(repo, changes_list, %{timeout: timeout, timestamps: timestamps} = options) when is_list(changes_list) do
    on_conflict = Map.get_lazy(options, :on_conflict, &default_on_conflict/0)

    combined_changes = changes_list |> Enum.reduce(%{}, &compose_change/2)

    # Enforce CoinBalanceDaily ShareLocks order (see docs: sharelocks.md)
    ordered_changes_list = combined_changes |> Map.values() |> Enum.sort_by(&{&1.address_hash, &1.epoch})

    {:ok, _} =
      Import.insert_changes_list(
        repo,
        ordered_changes_list,
        conflict_target: [:address_hash, :epoch],
        on_conflict: on_conflict,
        for: AddressVerifyDaily,
        timeout: timeout,
        timestamps: timestamps
      )

    {:ok, Enum.map(ordered_changes_list, &Map.take(&1, ~w(address_hash epoch verify_count)a))}
  end

  defp compose_change(change, acc) do
    Map.update(acc, {change.address_hash, change.epoch}, change, fn existing_change ->
      %{existing_change | verify_count: existing_change.verify_count + change.verify_count}
    end)
  end

  def default_on_conflict do
    from(
      addressVerifyDaily in AddressVerifyDaily,
      update: [
        set: [
          verify_count: fragment("EXCLUDED.verify_count + ?", addressVerifyDaily.verify_count),
          inserted_at: fragment("LEAST(EXCLUDED.inserted_at, ?)", addressVerifyDaily.inserted_at),
          updated_at: fragment("GREATEST(EXCLUDED.updated_at, ?)", addressVerifyDaily.updated_at)
        ]
      ],
      where: fragment("EXCLUDED.verify_count IS NOT NULL")
    )
  end
end
