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

    raw_price * price_multiplier
  end

  defp compute_price_with_primary_quote_asset(request = %PriceRequest{token_x: token_x, token_y: token_y}, pair_addr, active_bin) do

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
    related_price_in_dollars = compute_price_in_dollars(stable_related_pair, request.network, request.version)

    price = compute_x_div_y_price(request, active_bin)
    price_y_in_dollars = related_price_in_dollars / price

    has_enough_liquidity? =
      LbPair.pair_has_enough_reserves_around_active_bin?(
        token_x,
        token_y,
        pair_addr,
        active_bin,
        request.network,
        related_price_in_dollars,
        price_y_in_dollars
      )

    if has_enough_liquidity? do
      price
    else
      -1
    end
  end

  defp compute_price_without_primary_quote_asset(
         request = %PriceRequest{token_x: token_x, token_y: token_y, version: version, network: network},
         pair_addr,
         active_bin
       ) do
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
        # First we need to find pairs with a primary quote asset which is not an stable (i.e.: AVAX)
        # Then compute the price of AVAX in dollars
        # Use that price to get the price of X or Y in dollars, and from it the
        related_with_x =
          PairsInfoFetcher.find_pairs_with_token_and_primary_quote_asset(token_x, version, network)

        related_with_y =
          PairsInfoFetcher.find_pairs_with_token_and_primary_quote_asset(token_y, version, network)

        -1 # TODO
      {[token_x_related | _], []} ->
        x_price_in_dollars = compute_price_in_dollars(token_x_related, network, version)
        price = compute_x_div_y_price(request, active_bin)
        y_price_in_dollars = x_price_in_dollars / price

        has_enough_liquidity? =
          LbPair.pair_has_enough_reserves_around_active_bin?(
            token_x,
            token_y,
            pair_addr,
            active_bin,
            request.network,
            x_price_in_dollars,
            y_price_in_dollars
          )

        if has_enough_liquidity? do
          price
        else
          -1
        end

      {[], [token_y_related | _]} ->
        y_price_in_dollars = compute_price_in_dollars(token_y_related, network, version)
        price = compute_x_div_y_price(request, active_bin)
        x_price_in_dollars = y_price_in_dollars / price

        has_enough_liquidity? =
          LbPair.pair_has_enough_reserves_around_active_bin?(
            token_x,
            token_y,
            pair_addr,
            active_bin,
            request.network,
            x_price_in_dollars,
            y_price_in_dollars
          )

        if has_enough_liquidity? do
          price
        else
          -1
        end

      {[token_x_related | _], [token_y_related | _]} ->
        x_price_in_dollars = compute_price_in_dollars(token_x_related, network, version)
        price = compute_x_div_y_price(request, active_bin)
        y_price_in_dollars = x_price_in_dollars / price

        has_enough_liquidity? =
          LbPair.pair_has_enough_reserves_around_active_bin?(
            token_x,
            token_y,
            pair_addr,
            active_bin,
            request.network,
            x_price_in_dollars,
            y_price_in_dollars
          )

        if has_enough_liquidity? do
          price
        else
          -1
        end
    end
  end

  defp compute_price_in_dollars(%PairCacheEntry{} = stable_related_pair, network, version) do
    request_for_related = %PriceRequest{
      token_x: stable_related_pair.token_x,
      token_y: stable_related_pair.token_y,
      bin_step: stable_related_pair.bin_step,
      network: network,
      version: version
    }

    %Pair{price: related_price_in_dollars} =
      related_pair_info =
      PairRepository.fetch_pair_info(stable_related_pair.pair_address, request_for_related)

    related_price_in_dollars
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
end
