class RequestToken < Authorization

  def authorize!(account)
    return false if authorized?
    self.account=account
    self.authorized_at=Time.now.utc
    self.save
  end

  def exchange!
    return false unless authorized?
    RequestToken.transaction do
      access_token=AccessToken.create(:account => account, :api_key => api_key)
      invalidate!
      access_token
    end
  end
end
