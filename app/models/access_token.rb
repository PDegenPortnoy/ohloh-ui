class AccessToken < Authorization
  validates_presence_of :account
  before_create :set_authorized_at

  protected

  def set_authorized_at
    self.authorized_at=Time.now.utc
  end
end
