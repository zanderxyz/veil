defmodule Veil.Secure do
  @moduledoc """
  Veil.Secure is a module for generating secure session ids to be used by Veil.
  """

  alias Veil.Secret

  @doc """
  To form a secure id, we concatenate together:
  * 24-40 random bytes
  * user ip address
  * user agent string
  * system time in ms
  * server secret (re-generated every time the server starts)

  Then SHA256 the result, and encode in Base32 (so we can transmit it as part of a URL).
  """
  def generate_unique_id(conn) do
    random_prefix = :crypto.strong_rand_bytes(23 + :rand.uniform(17))

    client_ip = get_user_ip(conn)

    user_agent =
      conn
      |> Plug.Conn.get_req_header("user-agent")
      |> List.first()

    system_time_ms = :os.system_time() |> to_string()

    secret = Secret.get()

    concatenated = random_prefix <> client_ip <> user_agent <> system_time_ms <> secret
    hashed = :crypto.hash(:sha256, concatenated)
    Base.encode32(hashed)
  end

  @doc """
  Gets the IP address of the client
  """
  def get_user_ip(conn) do
    forwarded_ip =
      conn
      |> Plug.Conn.get_req_header("x-forwarded-for")
      |> List.first()

    unless is_nil(forwarded_ip) do
      forwarded_ip
    else
      conn.remote_ip
      |> Tuple.to_list()
      |> join_ip()
    end
  end

  defp join_ip(list) do
    case length(list) do
      8 -> Enum.join(list, ":")
      _ -> Enum.join(list, ".")
    end
  end
end
