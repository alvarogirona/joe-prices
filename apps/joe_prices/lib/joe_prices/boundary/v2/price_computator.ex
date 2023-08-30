defmodule JoePrices.Boundary.V2.PriceComputator do
  @moduledoc """
  Module for computing the price of a pair of tokens.

  It also checks that there is enough liquidity (>10$) arount =-5 bins of the active
  """

  alias JoePrices.Contracts.V21.LbPair
  alias JoePrices.Boundary.V2.PairRepository
  alias JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher
  alias JoePrices.Core.Tokens.Stable
  alias JoePrices.Boundary.V2.PriceRequest
  alias JoePrices.Core.V21.Pair
  alias JoePrices.Boundary.Token.TokenInfoFetcher

  @spec compute_price(PriceRequest.t(), non_neg_integer()) :: float()
  def compute_price(request = %PriceRequest{}, active_bin) do
    cond do
      has_stable_in_tokens(request) ->
        compute_x_div_y_price(request, active_bin)

      has_primary_quote_asset(request) ->
        compute_price_with_primary_quote_asset(request, active_bin)

      true ->
        -1
    end
  end

  defp compute_x_div_y_price(request = %PriceRequest{}, active_bin) do
    token_x_decimals = TokenInfoFetcher.get_decimals_for_token(request.token_x)
    token_y_decimals = TokenInfoFetcher.get_decimals_for_token(request.token_y)

    raw_price = JoePrices.Core.V21.Bin.get_price_from_id(active_bin, request.bin_step)
    price_multiplier = :math.pow(10, token_x_decimals - token_y_decimals)

    if request.token_x < request.token_y do
      raw_price * price_multiplier
    else
      1 / raw_price * price_multiplier
    end
  end

  defp compute_price_with_primary_quote_asset(request = %PriceRequest{}, active_bin) do
    [token_x, token_y] = sorted_tokens(request.token_x, request.token_y)

    stable_pairs_token_x =
      PairsInfoFetcher.find_stable_pairs_with_token(
        token_x,
        request.version,
        request.network
      )

    stable_pairs_token_y =
      PairsInfoFetcher.find_stable_pairs_with_token(
        token_y,
        request.version,
        request.network
      )

    case {stable_pairs_token_x, stable_pairs_token_y} do
      {[], []} ->
        throw("no pairs")

      {[stable_related_pair | _token_x_pairs], []} ->
        request_for_x = %PriceRequest{
          token_x: stable_related_pair.token_x,
          token_y: stable_related_pair.token_y,
          bin_step: stable_related_pair.bin_step,
          network: request.network
        }

        %Pair{price: related_price} =
          p_info = PairRepository.fetch_pair_info(stable_related_pair.pair_address, request_for_x)

        price = compute_x_div_y_price(request, active_bin)

        -2

      {[], [stable_related_pair | _token_y_pairs]} ->
        request_for_y = %PriceRequest{
          token_x: stable_related_pair.token_x,
          token_y: stable_related_pair.token_y,
          bin_step: stable_related_pair.bin_step,
          network: request.network
        }

        p_info = PairRepository.fetch_pair_info(stable_related_pair.pair_address, request_for_y)

        price = compute_x_div_y_price(request, active_bin)

        -2

      {[stable_pair_x | _], [_stable_pair_y | _]} ->
        request_for_x = %PriceRequest{
          token_x: stable_pair_x.token_x,
          token_y: stable_pair_x.token_y,
          bin_step: stable_pair_x.bin_step,
          network: request.network
        }

        %Pair{price: related_price} =
          p_info = PairRepository.fetch_pair_info(stable_pair_x.pair_address, request_for_x)

        price = compute_x_div_y_price(request, active_bin)
        # Uncomment to return price in dolars
        price_in_dollars = related_price / price

        price
    end
  end

  defp has_primary_quote_asset(
         request = %PriceRequest{network: network, token_x: tx, token_y: ty}
       ) do
    downcased_tx = String.downcase(tx)
    downcased_ty = String.downcase(ty)

    Pair.is_primary_quote_asset?(downcased_tx, network) or
      Pair.is_primary_quote_asset?(downcased_ty, network)
  end

  defp has_stable_in_tokens(%PriceRequest{token_x: tx, token_y: ty, network: nw}) do
    Stable.is_token_stable(tx, nw) or Stable.is_token_stable(ty, nw)
  end

  defp sorted_tokens(token_x, token_y) when token_x < token_y, do: [token_x, token_y]
  defp sorted_tokens(token_x, token_y), do: [token_y, token_x]
end
