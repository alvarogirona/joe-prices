defmodule JoePrices.Utils.Parallel do
  require Logger

  def pmap(collection, func) do
    collection
    |> Task.async_stream(func)
    |> Enum.map(fn
      {:ok, result} -> result
      {:error, _} = error -> error
    end)
  end
end
