require 'oauth/signature'
module OAuth
  module Rails
   
    module ControllerMethods
      protected
      
      def current_token
        @current_token
      end
      
      def current_api_key
        @current_api_key
      end
      
      def oauthenticate
        verified=verify_oauth_signature 
        return verified && current_token.is_a?(::AccessToken)
      end
      
      def oauth?
        current_token!=nil
      end
      
      # use in a before_filter
      def oauth_required
        if oauthenticate
          if authorized?
            return true
          else
            invalid_oauth_response
          end
        else
          invalid_oauth_response
        end
      end
      
      # This requies that you have an acts_as_authenticated compatible authentication plugin installed
      def login_or_oauth_required
        if oauthenticate
          if authorized?
            return true
          else
            invalid_oauth_response
          end
        else
          login_required
        end
      end
      
      
      # verifies a request token request
      def verify_oauth_consumer_signature
        begin
          valid = ApiKey.verify_request(request) do |token, consumer_key|
            @current_api_key = ApiKey.find_by_key(consumer_key)

            # return the token secret and the consumer secret
            [nil, @current_api_key.secret]
          end
        rescue
          valid=false
        end

        invalid_oauth_response unless valid
      end

      def verify_oauth_request_token
				invalid_oauth_response unless verify_oauth_signature && current_token.is_a?(::RequestToken)
      end

      def invalid_oauth_response(code=401,message="Invalid OAuth Request")
        render :text => message, :status => code
      end

    private
      
      def current_token=(token)
        @current_token=token
        if @current_token
          @current_api_key=@current_token.api_key 
        end
        @current_token
      end
      
      # Implement this for your own application using app-specific models
      def verify_oauth_signature
        begin
          valid = ApiKey.verify_request(request) do |token, consumer_key, nonce, timestamp|
            self.current_token = ApiKey.find_token(token)
            # return the token secret and the consumer secret
            [(current_token.nil? ? nil : current_token.secret), (current_api_key.nil? ? nil : current_api_key.secret)]
          end
					valid
				end
			end
      
    end
  end
end
