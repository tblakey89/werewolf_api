defmodule WerewolfApi.Game.DynamicLink do
  @behaviour WerewolfApi.Game.DynamicLinkBehaviour
  alias GoogleApi.FirebaseDynamicLinks.V1.Api.ShortLinks
  alias GoogleApi.FirebaseDynamicLinks.V1.Model.CreateManagedShortLinkRequest
  alias GoogleApi.FirebaseDynamicLinks.V1.Model.DynamicLinkInfo
  alias GoogleApi.FirebaseDynamicLinks.V1.Model.AndroidInfo
  alias GoogleApi.FirebaseDynamicLinks.V1.Model.IosInfo
  alias GoogleApi.FirebaseDynamicLinks.V1.Model.SocialMetaTagInfo

  # https://hexdocs.pm/google_api_firebase_dynamic_links/api-reference.html
  # don't forget to either put the ids below in env, or in prod secrets

  def new_link(invitation_token) do
    {:ok, response} =
      ShortLinks.firebasedynamiclinks_short_links_create(
        connection(),
        key: Application.get_env(:werewolf_api, :dynamic_links)[:firebase_api],
        body: %CreateManagedShortLinkRequest{
          dynamicLinkInfo: %DynamicLinkInfo{
            link: "https://www.wolfchat.app/invitation/#{invitation_token}",
            domainUriPrefix: "wolfchat.page.link",
            androidInfo: %AndroidInfo{
              androidPackageName: "com.wolfchat.wolfchat_app"
            },
            iosInfo: %IosInfo{
              iosBundleId: Application.get_env(:werewolf_api, :dynamic_links)[:bundle_id],
              iosAppStoreId: Application.get_env(:werewolf_api, :dynamic_links)[:app_store_id]
            },
            socialMetaTagInfo: %SocialMetaTagInfo{
              socialDescription:
                "Follow the link to join your friends on the WolfChat app for a game of Werewolf.",
              socialImageLink:
                "https://werewolf-frontend.s3.eu-west-2.amazonaws.com/Icon-512.png",
              socialTitle: "WolfChat"
            }
          }
        }
      )

    response.shortLink
  end

  defp connection do
    GoogleApi.FirebaseDynamicLinks.V1.Connection.new()
  end
end
