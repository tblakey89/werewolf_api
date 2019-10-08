defmodule GoogleToken do
  use Joken.Config

  add_hook(JokenJwks, strategy: GoogleAuthStrategy)

  def token_config do
    
  end
end
