module RedirectUriValidatorPatch
  private

  def invalid_ssl_uri?(uri)
    forces_ssl = Doorkeeper.configuration.force_ssl_in_redirect_uri
    forces_ssl && non_localhost_url(uri) && uri.try(:scheme) != 'https'
  end

  def non_localhost_url(uri)
    not uri.path.match /http:\/\/localhost/
  end
end
