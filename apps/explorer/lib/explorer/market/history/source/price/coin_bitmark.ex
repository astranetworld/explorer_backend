defmodule Explorer.Market.History.Source.Price.CoinBitMart do
  @moduledoc """
  Adapter for fetching current market from CoinGecko.
  """

  alias Explorer.ExchangeRates.Source
  alias Explorer.ExchangeRates.Source.CoinBitMart, as: ExchangeRatesSourceCoinBitMart
  alias Explorer.Market.History.Source.Price, as: SourcePrice
  alias Explorer.Market.History.Source.Price.CryptoCompare

  require Logger

  @behaviour SourcePrice

  @impl SourcePrice
  def fetch_price_history(_previous_days \\ nil) do
    url = ExchangeRatesSourceCoinBitMart.source_url()

    if url do
      case Source.http_request(url, ExchangeRatesSourceCoinBitMart.headers()) do
        {:ok, data} ->
          result =
            data
            |> format_data()

          {:ok, result}

        _ ->
          :error
      end
    else
      :error
    end
  end

  @spec format_data(term()) :: SourcePrice.record() | nil
  defp format_data(nil), do: nil

  defp format_data(%{"data" => _} = json_data) do
    market_data = json_data["data"]

#    Logger.error("===bitmart----market_data--#{market_data["close_24h"]}===#{market_data["timestamp"]}==#{market_data["open_24h"]}}")
    [
      %{
        closing_price: Decimal.new(to_string(market_data["close_24h"])),
        date: CryptoCompare.date(System.system_time(:second)),
        opening_price: Decimal.new(to_string(market_data["open_24h"]))
      }
    ]
  end
end
