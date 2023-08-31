defmodule JoePrices.Boundary.V2.PriceComputator do
  @moduledoc """
  Module for computing the price of a pair of tokens.

  It also checks that there is enough liquidity (>10$) arount =-5 bins of the active
  """

  alias JoePrices.Core.V2.Token
  alias JoePrices.Contracts.V21.LbPair
  alias JoePrices.Boundary.V2.PairRepository
  alias JoePrices.Boundary.V2.PairInfoCache.PairCacheEntry
  alias JoePrices.Boundary.V2.PairInfoCache.PairsInfoFetcher
  alias JoePrices.Core.Tokens.Stable
  alias JoePrices.Boundary.V2.PriceRequest
  alias JoePrices.Core.V2.Pair
  alias JoePrices.Boundary.Token.TokenInfoFetcher

  @spec compute_price(PriceRequest.t(), String.t(), non_neg_integer()) :: float()
  def compute_price(request = %PriceRequest{}, pair_addr, active_bin) do
    cond do
      has_stable_in_tokens(request) ->
        compute_x_div_y_price(request, active_bin)

      # Example BTC.b/Avax
      has_primary_quote_asset(request) ->
        compute_price_with_primary_quote_asset(request, pair_addr, active_bin)

      # Does not have a primary quote asset. Example: WETH/BTC.b in Avalanche
      true ->
        compute_price_without_primary_quote_asset(request, pair_addr, active_bin)
    end
  end

  defp compute_x_div_y_price(request = %PriceRequest{}, active_bin) do
    token_x_decimals = TokenInfoFetcher.get_decimals_for_token(request.token_x)
    token_y_decimals = TokenInfoFetcher.get_decimals_for_token(request.token_y)

    raw_price = JoePrices.Core.V2.Bin.get_price_from_id(active_bin, request.bin_step)
    price_multiplier = :math.pow(10, token_x_decimals - token_y_decimals)

    # if request.token_x < request.token_y do
    raw_price * price_multiplier
    # else
    #   (1 / raw_price) * price_multiplier
    # end
  end

  defp compute_price_with_primary_quote_asset(request = %PriceRequest{}, pair_addr, active_bin) do
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
        -1
      {[stable_related_pair | _token_x_pairs], []} ->
        compute_price_with_related_stable(request, stable_related_pair, pair_addr, active_bin)
      {[], [stable_related_pair | _token_y_pairs]} ->
        compute_price_with_related_stable(request, stable_related_pair, pair_addr, active_bin)
      {[stable_pair_x | _], [_stable_pair_y | _]} ->
        compute_price_with_related_stable(request, stable_pair_x, pair_addr, active_bin)
    end
  end

  defp compute_price_with_related_stable(
         %PriceRequest{token_x: token_x, token_y: token_y} = request,
         %PairCacheEntry{} = stable_related_pair,
         pair_addr,
         active_bin
       ) do
    request_for_related = %PriceRequest{
      token_x: stable_related_pair.token_x,
      token_y: stable_related_pair.token_y,
      bin_step: stable_related_pair.bin_step,
      network: request.network,
      version: request.version
    }

    %Pair{price: price_related_in_dollars} =
      p_info =
      PairRepository.fetch_pair_info(stable_related_pair.pair_address, request_for_related)

    price = compute_x_div_y_price(request, active_bin)
    price_y_in_dollars = price_related_in_dollars / price

    has_enough_liquidity? =
      LbPair.pair_has_enough_reserves_around_active_bin?(
        token_x,
        token_y,
        pair_addr,
        active_bin,
        request.network,
        price_related_in_dollars,
        price_y_in_dollars
      )

    if has_enough_liquidity? do
      price
    else
      -1
    end
  end

  defp compute_price_without_primary_quote_asset(request = %PriceRequest{token_x: token_x, token_y: token_y}, pair_addr, active_bin) do
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
      {[], []} -> -1
      {[token_x_related | _], []} -> -2
      {[], [token_y_related | _]} -> -3
      {[token_x_related | _], [token_y_related | _]} -> -4
    end
  end

  defp has_primary_quote_asset(
         request = %PriceRequest{network: network, token_x: tx, token_y: ty}
       ) do
    downcased_tx = String.downcase(tx)
    downcased_ty = String.downcase(ty)

    Token.is_primary_quote_asset?(downcased_tx, network) or
      Token.is_primary_quote_asset?(downcased_ty, network)
  end

  defp has_stable_in_tokens(%PriceRequest{token_x: tx, token_y: ty, network: nw}) do
    Stable.is_token_stable(tx, nw) or Stable.is_token_stable(ty, nw)
  end

  defp sorted_tokens(token_x, token_y) when token_x < token_y, do: [token_x, token_y]
  defp sorted_tokens(token_x, token_y), do: [token_y, token_x]
end
