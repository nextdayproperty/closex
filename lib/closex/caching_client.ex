defmodule Closex.CachingClient do
  @behaviour Closex.ClientBehaviour

  @moduledoc """
  TODO: Add documentation for using CachingClient
  """

  @fallback_client Application.get_env(:closex, :fallback_client, Closex.HTTPClient)

  defdelegate find_leads(search_term, opts \\ []), to: @fallback_client

  def get_lead(lead_id, opts \\ []) do
    get_cached(lead_id, {:get_lead, [lead_id, opts]})
  end

  defdelegate create_lead(payload, opts \\ []), to: @fallback_client
  defdelegate update_lead(lead_id, payload, opts \\ []), to: @fallback_client

  def get_opportunity(opportunity_id, opts \\ []) do
    get_cached(opportunity_id, {:get_opportunity, [opportunity_id, opts]})
  end

  defdelegate create_opportunity(payload, opts \\ []), to: @fallback_client
  defdelegate update_opportunity(opportunity_id, payload, opts \\ []), to: @fallback_client

  def get_lead_custom_field(custom_field_id, opts \\ []) do
    get_cached(custom_field_id, {:get_lead_custom_field, [custom_field_id, opts]})
  end

  def get_organization(organization_id, opts \\ []) do
    get_cached(organization_id, {:get_organization, [organization_id, opts]})
  end

  def get_lead_statuses(opts \\ []) do
    get_cached(:get_lead_statuses, {:get_lead_statuses, [opts]})
  end

  def get_opportunity_statuses(opts \\ []) do
    get_cached(:get_opportunity_statuses, {:get_opportunity_statuses, [opts]})
  end

  defdelegate send_email(payload, opts \\ []), to: @fallback_client

  def get_users(opts \\ []) do
    get_cached(:get_users, {:get_users, [opts]})
  end

  defp get_cached(key, {fun, args}) do
    cache_result = Cachex.get(:closex_cache, key, fallback: fn _key ->
      case apply(@fallback_client, fun, args) do
        result = {:ok, _} ->
          {:commit, result}
        error = {:error, _} ->
          {:ignore, error}
      end
    end)

    case cache_result do
      {:loaded, result} ->
        Closex.log fn -> "[Closex.CachingClient] MISS for key: #{key}" end
        result
      {:ok, result} ->
        Closex.log fn -> "[Closex.CachingClient] HIT for key: #{key}" end
        result
      error ->
        Closex.log fn -> "[Closex.CachingClient] ERROR for key: #{key}" end
        {:error, error}
    end
  end
end
