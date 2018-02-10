defmodule <%= main_module %>.Veil.Request do
  @moduledoc """
  Veil's Request Schema - a request is a login attempt
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias <%= main_module %>.Veil.User

  schema "veil_requests" do
    field(:unique_id, :string)
    field(:phoenix_token, :string)
    field(:ip_address, :string)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:unique_id, :phoenix_token, :user_id, :ip_address])
    |> validate_required([:unique_id, :phoenix_token, :user_id, :ip_address])
  end
end
