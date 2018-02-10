defmodule <%= main_module %>.Repo.Migrations.AddVeil do
  use Ecto.Migration

  def change do
    create table(:veil_users) do
      add(:email, :string)
      add(:verified, :boolean, default: false)

      timestamps()
    end

    create(unique_index(:veil_users, [:email]))

    create table(:veil_requests) do
      add(:user_id, references(:veil_users, on_delete: :delete_all))
      add(:unique_id, :string)
      add(:phoenix_token, :string)
      add(:ip_address, :string)

      timestamps()
    end

    create(index(:veil_requests, [:unique_id]))

    create table(:veil_sessions) do
      add(:user_id, references(:veil_users, on_delete: :delete_all))
      add(:unique_id, :string)
      add(:phoenix_token, :string)
      add(:ip_address, :string)

      timestamps()
    end

    create(index(:veil_sessions, [:unique_id]))
  end
end
