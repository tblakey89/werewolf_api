defmodule WerewolfApi.Game.DynamicLinkBehaviour do
  @moduledoc false
  @callback new_link(String.t()) :: String.t()
end
