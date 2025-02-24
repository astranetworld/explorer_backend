defmodule BlockScoutWeb.BlockVerifiersController do
  use BlockScoutWeb, :controller

  import BlockScoutWeb.Chain,
    only: [paging_options: 1, put_key_value_to_paging_options: 3, next_page_params: 3, split_list_by_page: 1]

  import Explorer.Chain, only: [hash_to_block: 2, number_to_block: 2, string_to_block_hash: 1]

  alias BlockScoutWeb.{Controller, BlockVerifiersView}
  alias Explorer.Chain
  alias Phoenix.View
  require  Logger

  def index(conn, %{"block_hash_or_number" => formatted_block_hash_or_number, "type" => "JSON"} = params) do
    case param_block_hash_or_number_to_block(formatted_block_hash_or_number, []) do
      {:ok, block} ->
        full_options =
          Keyword.merge(
            [
              necessity_by_association: %{
                [miner: :names] => :optional,
                :block_verifiers_rewards => :optional
              }
            ],
            put_key_value_to_paging_options(paging_options(params), :is_index_in_asc_order, true)
          )

        verifier_plus_one = Chain.block_to_verifiers(block.hash, full_options)
       # total_supply = Chain.total_supply()

        {verifiers, next_page} = split_list_by_page(verifier_plus_one)

        #Logger.warn("---verifiers---#{inspect(verifiers)}---");

        next_page_path =
          case next_page_params(next_page, verifiers, params) do
            nil ->
              nil

            next_page_params ->
              block_verifier_path(
                conn,
                :index,
                block,
                Map.delete(next_page_params, "type")
              )
          end

        items_count_str = Map.get(params, "items_count")

        items_count =
          if items_count_str do
            {items_count, _} = Integer.parse(items_count_str)
            items_count
          else
            0
          end

        items =
          verifiers
          |> Enum.with_index(1)
          |> Enum.map(fn {verifier, index} ->
            View.render_to_string(
              BlockVerifiersView,
              "_tile.html",
              verifiers: verifier,
              index: index + items_count
            )
          end)

        # Logger.info("==index-====2222===#{inspect(items)}")

        json(
          conn,
          %{
            items: items,
            next_page_path: next_page_path
          }
        )

      {:error, {:invalid, :hash}} ->
        not_found(conn)

      {:error, {:invalid, :number}} ->
        not_found(conn)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render(
          "404.html",
          block: nil,
          block_above_tip: block_above_tip(formatted_block_hash_or_number)
        )
    end
  end

  def index(conn, %{"block_hash_or_number" => formatted_block_hash_or_number}) do
    case param_block_hash_or_number_to_block(formatted_block_hash_or_number,
           necessity_by_association: %{
             [miner: :names] => :optional,
             :uncles => :optional,
             :nephews => :optional,
             :rewards => :optional,
             :block_verifiers_rewards => :optional,
             :block_minner_rewards => :optional
           }
         ) do
      {:ok, block} ->
        block_transaction_count = Chain.block_to_transaction_count(block.hash)
        block_miner_verifier_count = Chain.block_to_miner_verifier_count(block.hash)
        block_miner_rewards_count = Chain.block_to_miner_rewards_count(block.hash)
        render(
          conn,
          "index.html",
          block: block,
          block_transaction_count: block_transaction_count,
          block_miner_verifier_count: block_miner_verifier_count,
          block_miner_rewards_count: block_miner_rewards_count,
          current_path: Controller.current_full_path(conn)
        )
      {:error, {:invalid, :hash}} ->
        not_found(conn)

      {:error, {:invalid, :number}} ->
        not_found(conn)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render(
          "404.html",
          block: nil,
          block_above_tip: block_above_tip(formatted_block_hash_or_number)
        )
    end
  end

  def param_block_hash_or_number_to_block("0x" <> _ = param, options) do
    case string_to_block_hash(param) do
      {:ok, hash} ->
        hash_to_block(hash, options)

      :error ->
        {:error, {:invalid, :hash}}
    end
  end

  def param_block_hash_or_number_to_block(number_string, options)
      when is_binary(number_string) do
    case BlockScoutWeb.Chain.param_to_block_number(number_string) do
      {:ok, number} ->
        number_to_block(number, options)

      {:error, :invalid} ->
        {:error, {:invalid, :number}}
    end
  end

  defp block_above_tip("0x" <> _), do: {:error, :hash}

  defp block_above_tip(block_hash_or_number) when is_binary(block_hash_or_number) do
    case Chain.max_consensus_block_number() do
      {:ok, max_consensus_block_number} ->
        {block_number, _} = Integer.parse(block_hash_or_number)
        {:ok, block_number > max_consensus_block_number}

      {:error, :not_found} ->
        {:ok, true}
    end
  end
end
