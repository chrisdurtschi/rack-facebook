require 'rack/request'
require 'rack/mock'
require File.expand_path(File.dirname(__FILE__) + '/../lib/rack/facebook/original_verifier')
require File.expand_path(File.dirname(__FILE__) + '/../lib/rack/facebook/new_verifier')

APP_NAME = 'my_app'
SECRET = "123456789"
API_KEY = "616313"
COOKIE_NAME = "fbs_#{API_KEY}"

def calculate_signature(hash)
  raw_string = hash.map{ |*pair| pair.join('=') }.sort.join
  Digest::MD5.hexdigest([raw_string, SECRET].join)
end

def sign_hash(hash, prefix)
  fb_hash = hash.inject({}) do |all, (key, value)|
    all[key.sub("#{prefix}_", "")] = value if key.index("#{prefix}_") == 0
    all
  end
  hash.merge(prefix => calculate_signature(fb_hash))
end

def sign_params(hash)
  sign_hash(hash, "fb_sig")
end

def sign_cookies(hash)
  sign_hash(hash, API_KEY)
end

def mock_post(app, env)
  facebook = described_class.new(app, :application_name => APP_NAME, :application_secret => SECRET, :api_key => API_KEY)
  request = Rack::MockRequest.new(facebook)
  @response = request.post("/", env)
end

def post_env(params)
  # set up form variables like rack::request had parsed them
  env = {"rack.request.form_hash" => params}
  env["rack.request.form_input"] = env["rack.input"] = "fb"
  env
end

def post_request(app, params)
  mock_post app, post_env(params)
end

def cookie_env(cookies)
  # set up the cookie hash like rack::request would
  env = {"rack.request.cookie_hash" => cookies}
  env["rack.request.cookie_string"] = env["HTTP_COOKIE"] = cookies.collect {|k,v| "#{k}=#{v}"}.join('; ')
  env
end

def cookie_request(app, cookies)
  mock_post app, cookie_env(cookies)
end

def request
  @request
end

def response
  @response
end

def response_env(status = 200)
  [status, {"Content-type" => "test/plain", "Content-length" => "5"}, ["hello"]]
end

def app
  @app ||= lambda do |env|
    @request = Rack::Request.new(env)
    response_env
  end
end
