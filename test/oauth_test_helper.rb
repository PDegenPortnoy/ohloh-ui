require 'oauth'
#require 'hmac-sha1'

class RequestMock < OAuth::RequestProxy::Base
	attr_accessor :method, :uri, :parameters
	def initialize(method, uri, parameters)
		@method = method
		@uri = uri
		@parameters = parameters
    @unsigned_parameters = []
	end
end

def default_oauth_parameters(api_key, token=nil)
	params = {
		'oauth_consumer_key' => api_key.key,
		'oauth_signature_method' => 'HMAC-SHA1',
		'oauth_nonce' => '1',
		'oauth_timestamp' => '1'
	}
	params['oauth_token'] = token.token if token
	params
end

def oauth_header(params={})
	'OAuth ' + params.collect { |k,v| "#{URI.escape(k)}=#{URI.escape(v).gsub(/=/,'%3D')}" }.join(",")
end
