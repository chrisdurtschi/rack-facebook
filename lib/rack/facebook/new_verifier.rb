# Validates cookie signature of the new connect-js library
# http://wiki.github.com/facebook/connect-js/faq
# http://blog.mealstrom.com/2009/12/using-the-new-facebook-connect-library-including-with-facebooker/

require 'digest'
require 'rack/request'

module Rack
  module Facebook
    class NewVerifier
      def initialize(app, options, &condition)
        @app = app
        @options = options
        @condition = condition
      end

      def app_name
        @options[:application_name]
      end

      def secret
        @options[:application_secret]
      end

      def api_key
        @options[:api_key]
      end

      def call(env)
        request = Request.new(env)
        request.api_key = api_key

        if passes_condition?(request) and request.facebook?
          request.parse_cookie!
          
          # use the hash to verify all components are present, returning gracefully if any are missing or invalid
          return @app.call(env) unless request.cookie_params["sig"] && request.cookie_params['session_key'] && request.cookie_params['uid'] && request.cookie_params['expires'] && request.cookie_params['secret'] 
          return @app.call(env) unless Time.at(request.cookie_params['expires'].to_s.to_f) > Time.now || (request.cookie_params['expires'] == "0")

          valid = valid_signature?(request.cookie_auth_string, request.cookie_signature)

          if valid
            env["facebook.app_name"] = app_name
            env["facebook.api_key"] = api_key
            env["facebook.secret"] = secret
            env["facebook.uid"] = request.cookie_params["uid"]
          else
            return [400, {"Content-Type" => "text/html"}, ["Invalid Facebook signature"]]
          end
        end
        
        return @app.call(env)
      end

      private

      def passes_condition?(request)
        @condition.nil? or @condition.call(request.env)
      end

      def valid_signature?(auth_string, actual_sig)
        actual_sig == calculate_signature(auth_string)
      end

      def calculate_signature(auth_string)
        Digest::MD5.hexdigest([auth_string, secret].join)
      end

      class Request < ::Rack::Request
        attr_accessor :api_key, :cookie_params, :cookie_signature, :cookie_auth_string

        def facebook?
          !!facebook_cookie
        end

        def facebook_cookie
          cookies["fbs_#{@api_key}"]
        end
        
        def parse_cookie!
          @cookie_params = {}

          # now generate a list of individual parameters as well as the string to use to verify the signature
          # the string is the cookie value minus the sig parameter
          @cookie_auth_string = facebook_cookie.gsub(/\"/, "").split("&").collect { |parameter| 
            # parameter is, e.g., expires=1260910800
            key_and_value = parameter.split("=")
            # save it to the hash
            @cookie_params[key_and_value[0]] = key_and_value[1]

            # add it back to the string for sig verification, as long as it's not the expected sig value itself
            key_and_value[0] == "sig" ? nil : parameter
          }.compact.join # preserving the order of the string

          @cookie_signature = @cookie_params['sig']
        end

      end
    end
  end
end
