defmodule WerewolfApi.Game.DynamicLink do
  alias GoogleApi.FirebaseDynamicLinks.V1.Api.ShortLinks
  alias GoogleApi.FirebaseDynamicLinks.V1.Model.CreateManagedShortLinkRequest
  alias GoogleApi.FirebaseDynamicLinks.V1.Model.DynamicLinkInfo
  alias GoogleApi.FirebaseDynamicLinks.V1.Model.AndroidInfo
  alias GoogleApi.FirebaseDynamicLinks.V1.Model.IosInfo

  # https://hexdocs.pm/google_api_firebase_dynamic_links/api-reference.html
  # don't forget to either put the ids below in env, or in prod secrets

  def new_link(invitation_token) do
    {:ok, response} = ShortLinks.firebasedynamiclinks_short_links_create(
      connection(),
      key: System.get_env("FIREBASE_API"),
      body: %CreateManagedShortLinkRequest{
        dynamicLinkInfo: %DynamicLinkInfo{
          link: "https://www.wolfchat.app/invitation/#{invitation_token}",
          domainUriPrefix: "wolfchat.page.link",
          androidInfo: %AndroidInfo{
            androidPackageName: "com.wolfchat.wolfchat_app"
          },
          iosInfo: %IosInfo{
            iosBundleId: System.get_env("BUNDLE_ID")
          }
        },
      }
    )

    response.shortLink
  end

  defp connection do
    GoogleApi.FirebaseDynamicLinks.V1.Connection.new
  end
end
