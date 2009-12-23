require File.dirname(__FILE__) + '/../../spec_helper'

describe Rack::Facebook::NewVerifier do
  describe "without a block" do
    describe "cookie authentication" do
      describe "valid signature" do
        def valid_cookie
          @valid_cookie ||= %Q{"expires=1999999999&secret=ABC&session_key=XYZ&sig=aa973102227ba339a60c484a9bb7b111&uid=234433"}
        end
        
        it "should run app" do
          app = mock('rack app')
          app.should_receive(:call).with(instance_of(Hash)).and_return(response_env)

          cookie_request app, {COOKIE_NAME => valid_cookie}
          response.status.should == 200
        end
        
        it "should add app name, api_key, secret, and uid to the environment" do
          cookie_request app, {COOKIE_NAME => valid_cookie}

          request.env['facebook.app_name'].should == APP_NAME
          request.env['facebook.api_key'].should == API_KEY
          request.env['facebook.secret'].should == SECRET
          request.env['facebook.uid'].should == "234433"
        end
      end
      
      describe "invalid signature" do
        it "should not run app" do
          cookie_request mock('rack app'), {COOKIE_NAME => %Q{"expires=1999999999&secret=ABC&session_key=XYZ&sig=INVALID&uid=234433"}}
          response.status.should == 400
        end
      end
    end
  end
end
