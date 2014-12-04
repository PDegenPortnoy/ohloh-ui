class Authorization < ActiveRecord::Base
  belongs_to :api_key
  belongs_to :account
  validates_uniqueness_of :token
  validates_presence_of :api_key,:token,:secret
  before_validation(on: :create) { :generate_keys }
  scope :active, :conditions => ['invalidated_at IS NULL AND authorized_at IS NOT NULL']

  def invalidated?
    invalidated_at != nil
  end

  def invalidate!
    update_attribute :invalidated_at, Time.now.utc
  end

  def authorized?
    authorized_at && !invalidated?
  end

  def to_query
    "oauth_token=#{token}&oauth_token_secret=#{secret}"
  end

  protected

  def generate_keys
    @oauth_token=api_key.oauth_server.generate_credentials
    self.token=@oauth_token[0]
    self.secret=@oauth_token[1]
  end

end
