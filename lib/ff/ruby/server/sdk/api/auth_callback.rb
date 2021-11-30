require_relative "../connector/on_authorized"

class AuthCallback < OnAuthorized

  def on_auth_success

    raise "Not implemented"
  end
end