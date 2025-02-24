defmodule BlockScoutWeb.API.V2.AmcController do
  use BlockScoutWeb, :controller

  require Logger

  import BlockScoutWeb.Chain,
         only: [
           next_page_params: 3,
           paging_options: 1,
           split_list_by_page: 1,
           parse_block_hash_or_number_param: 1,
           put_key_value_to_paging_options: 3
         ]

  import BlockScoutWeb.PagingHelper, only: [delete_parameters_from_next_page_params: 1]

  alias Explorer.Chain
  alias Explorer.PagingOptions
  alias BlockScoutWeb.AccessHelper

  @api_true [api?: true]

  @block_params [
    necessity_by_association: %{
      [miner: :names] => :optional,
      :block_verifiers_rewards => :optional
    },
    api?: true
  ]

  @verify_daily_page_size 7

  action_fallback(BlockScoutWeb.API.V2.FallbackController)

  @spec verifiers(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def verifiers(conn, %{"block_hash_or_number" => block_hash_or_number} = params) do
    with {:ok, type, value} <- parse_block_hash_or_number_param(block_hash_or_number),
         {:ok, block} <- fetch_block(type, value, @api_true)do

      full_options =
        @block_params
        |> Keyword.merge(put_key_value_to_paging_options(paging_options(params), :is_index_in_asc_order, true))
        |> Keyword.merge(@api_true)

      verifier_plus_one = Chain.block_to_verifiers(block.hash, full_options)

      #%Explorer.PagingOptions{key: nil, page_size: 51, page_number: 1, is_pending_tx: false, is_index_in_asc_order: true, asc_order: false, batch_key: nil}, api?: true]
      #Logger.info(fn -> full_options end)

      {verifiers, next_page} = split_list_by_page(verifier_plus_one)

      next_page_params =
        next_page
        |> next_page_params(verifiers, delete_parameters_from_next_page_params(params))

      conn
      |> put_status(200)
      |> render(:verifiers, %{verifiers: verifiers, next_page_params: next_page_params})
    end
  end

  @spec verifiers(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def verifiers(conn, %{"address_hash_param" => address_hash_string} = params) do
    with {:format, {:ok, address_hash}} <- {:format, Chain.string_to_address_hash(address_hash_string)},
         {:ok, false} <- AccessHelper.restricted_access?(address_hash_string, params),
         {:not_found, {:ok, address}} <- {:not_found, Chain.hash_to_address(address_hash, @api_true, false)} do

      full_options =
        @block_params
        |> Keyword.merge(put_key_value_to_paging_options(paging_options(params), :is_index_in_asc_order, true))
        |> Keyword.merge(@api_true)

      verifier_plus_one = Chain.address_to_verifiers(address.hash, full_options)


      {verifiers, next_page} = split_list_by_page(verifier_plus_one)

      next_page_params =
        next_page
        |> next_page_params(verifiers, delete_parameters_from_next_page_params(params))

      conn
      |> put_status(200)
      |> render(:address_verify_list, %{verifiers: verifiers, next_page_params: next_page_params})
    end
  end


  @spec verify_daily(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def verify_daily(conn, %{"address_hash_param" => address_hash_string} = params) do
    with {:format, {:ok, address_hash}} <- {:format, Chain.string_to_address_hash(address_hash_string)},
         {:ok, false} <- AccessHelper.restricted_access?(address_hash_string, params),
         {:not_found, {:ok, address}} <- {:not_found, Chain.hash_to_address(address_hash, @api_true, false)} do

      start_epoch  =
        case Map.get(params, "epoch", nil) do
          epoch_str when is_binary(epoch_str) -> String.to_integer(epoch_str)
          nil -> block_number_to_epoch(Chain.block_height())
        end

      params = Map.put(params, "epoch", start_epoch)

      full_options =
        @api_true
        |> Keyword.merge(paging_options(params))

      address_verify_daily_plus_one = Chain.address_to_verify_daily(address.hash, full_options)


      {address_verify_daily, next_page} = Enum.split(address_verify_daily_plus_one, @verify_daily_page_size)

      next_page_params =
        next_page
        |> next_page_params(address_verify_daily, delete_parameters_from_next_page_params(params))

      conn
      |> put_status(200)
      |> render(:address_verify_daily, %{address_verify_daily: address_verify_daily, next_page_params: next_page_params})
    end
  end

  defp block_number_to_epoch(block_number) do
    beijing_block = Application.get_all_env(:indexer)[Indexer.Fetcher.Amc][:beijing_block]
    epoch_length = Application.get_all_env(:indexer)[Indexer.Fetcher.Amc][:apos_epoch]

    adjusted_number = block_number - beijing_block + 1
    div(adjusted_number - 1, epoch_length) + 1
  end

  @spec rewards(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def rewards(conn, %{"address_hash_param" => address_hash_string} = params) do
    with {:format, {:ok, address_hash}} <- {:format, Chain.string_to_address_hash(address_hash_string)},
         {:ok, false} <- AccessHelper.restricted_access?(address_hash_string, params),
         {:not_found, {:ok, address}} <- {:not_found, Chain.hash_to_address(address_hash, @api_true, false)} do

      full_options =
        @block_params
        |> Keyword.merge(put_key_value_to_paging_options(paging_options(params), :is_index_in_asc_order, true))
        |> Keyword.merge(@api_true)

      rewards_plus_one = Chain.address_to_miner_rewards(address.hash, full_options)

      {rewards, next_page} = split_list_by_page(rewards_plus_one)

      next_page_params =
        next_page
        |> next_page_params(rewards, delete_parameters_from_next_page_params(params))

      conn
      |> put_status(200)
      |> render(:address_rewards_list, %{rewards: rewards, next_page_params: next_page_params})
    end
  end

  @spec rewards(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def rewards(conn, %{"block_hash_or_number" => block_hash_or_number} = params) do
    with {:ok, type, value} <- parse_block_hash_or_number_param(block_hash_or_number),
         {:ok, block} <- fetch_block(type, value, @api_true)do

      full_options =
        @block_params
        |> Keyword.merge(put_key_value_to_paging_options(paging_options(params), :is_index_in_asc_order, true))
        |> Keyword.merge(@api_true)

      rewards_plus_one = Chain.block_to_miner_rewards(block.hash, full_options)

      {rewards, next_page} = split_list_by_page(rewards_plus_one)

      next_page_params =
        next_page
        |> next_page_params(rewards, delete_parameters_from_next_page_params(params))

      conn
      |> put_status(200)
      |> render(:rewards, %{rewards: rewards, next_page_params: next_page_params})
    end
  end

  defp fetch_block(:hash, hash, params) do
    Chain.hash_to_block(hash, params)
  end

  defp fetch_block(:number, number, params) do
    case Chain.number_to_block(number, params) do
      {:ok, _block} = ok_response ->
        ok_response

      _ ->
        {:lost_consensus, Chain.nonconsensus_block_by_number(number, @api_true)}
    end
  end
end