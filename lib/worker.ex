defmodule MetexNew.Worker do
  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  ## Helper Functions
  def get_temperature(pid, location) do
    GenServer.call(pid, {:location, location})
  end

  ## Server API
  def handle_call({:location, location}, _from, stats) do
    case temperature_of(location) do
      {:ok, temp} ->
        new_stats = update_stats(stats, location)
        {:reply, "#{temp}°c", new_stats}

      _ ->
        {:reply, :error, stats}
    end
  end

  defp temperature_of(location) do
    url_for(location) |> HTTPoison.get() |> parse_response()
  end

  defp url_for(location) do
    api_key = Application.fetch_env!(:metex_new, :openweather_api_key)

    "https://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{api_key}"
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> JSON.decode!() |> compute_temperature()
  end

  defp parse_response(_) do
    :error
  end

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  defp update_stats(old_stats, location) do
    case Map.has_key?(old_stats, location) do
      true -> Map.update!(old_stats, location, &(&1 + 1))
      false -> Map.put_new(old_stats, location, 1)
    end
  end
end
