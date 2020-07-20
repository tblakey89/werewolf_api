defmodule WerewolfApi.AppleCredential do
  def verify(code) do
    {:ok, %HTTPoison.Response{body: body}} =
      HTTPoison.post("https://appleid.apple.com/auth/token", request_body(code), request_header)

    Jason.decode!(body)
    |> handle_response
  end

  defp request_header do
    %{"Content-Type" => "application/x-www-form-urlencoded"}
  end

  defp request_body(code) do
    URI.encode_query(%{
      "client_id" => Application.get_env(:werewolf_api, :apple_auth)[:client_id],
      "client_secret" => generate_client_secret(),
      "code" => code,
      "grant_type" => "authorization_code",
      "redirect_uri" => "https://api/wolfchat.app/api/sessions/callback"
    })
  end

  defp generate_client_secret do
    # https://developer.apple.com/documentation/sign_in_with_apple/generate_and_validate_tokens
    timestamp = :os.system_time(:second)

    claims = %{
      "iss" => Application.get_env(:werewolf_api, :apple_auth)[:team_id],
      "iat" => timestamp,
      "exp" => timestamp + 300,
      "aud" => "https://appleid.apple.com",
      "sub" => Application.get_env(:werewolf_api, :apple_auth)[:client_id]
    }

    headers = %{
      "alg" => "ES256",
      # this is the ten char id on the filename of the key
      "kid" => Application.get_env(:werewolf_api, :apple_auth)[:private_key_id]
    }

    {_, jwt} =
      JOSE.JWT.sign(
        JOSE.JWK.from_pem(Application.get_env(:werewolf_api, :apple_auth)[:private_key]),
        headers,
        claims
      )
      |> JOSE.JWS.compact()

    jwt
  end

  defp handle_response(%{"id_token" => id_token}) do
    jwt_content = JOSE.JWT.peek_payload(id_token)
    {:ok, jwt_content.fields["sub"]}
  end

  defp handle_response(%{"error" => message}) do
    {:error, message}
  end
end
