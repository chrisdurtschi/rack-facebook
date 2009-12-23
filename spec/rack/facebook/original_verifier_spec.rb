require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Rack::Facebook::OriginalVerifier do
  describe "without a block" do
    describe "when the signature is not valid" do
      it "should fail with 400 Invalid Facebook signature" do
        post_request mock('rack app'), "fb_sig" => "INVALID"
        response.status.should == 400
      end
    end
    
    describe "when the fb_sig is valid" do
      def post(params)
        post_request(app, sign_params(params))
      end
      
      it "should convert the facebook parameters to ruby objects" do
        post "fb_sig_in_canvas" => "1", "fb_sig_time" => "1", "fb_sig_user" => "234433"
        
        request.env['facebook.time'].should == Time.at(1)
        request.env['facebook.in_canvas'].should be_true
        request.env['facebook.user'].should == "234433"
      end
      
      it "should add app name, api_key and secret to the environment" do
        post "fb_sig_in_canvas" => "1", "fb_sig_time" => "1", "fb_sig_user" => "234433"
        
        request.env['facebook.app_name'].should == APP_NAME
        request.env['facebook.api_key'].should == API_KEY
        request.env['facebook.secret'].should == SECRET
      end
      
      it "should strip facebook parameters from params hash" do
        post "fb_sig_in_canvas" => "1", "fb_sig_user" => "234433"

        request['fb_sig'].should be_nil
        request['fb_sig_user'].should be_nil
        request['fb_sig_in_canvas'].should be_nil
      end
      
      it "should not touch parameters not prefixed with \"fb_sig\"" do
        post "fb_sig_user" => "234433", "foo" => "bar"
        
        request['foo'].should == 'bar'
      end
      
      it "should split friend IDs into an array" do
        post "fb_sig_friends" => "2,3,5"
        
        request.env["facebook.friends"].should == ["2", "3", "5"]
      end
      
      it "should convert the request method from POST to the original client method" do
        post "fb_sig_request_method" => "PUT"
        
        request.request_method.should == 'PUT'
        request.env['facebook.original_method'].should == 'POST'
      end

      it "should call app" do
        @app = mock('rack app')
        @app.should_receive(:call).with(instance_of(Hash)).and_return(response_env)
        
        post "fb_sig_foo" => "bar"
        response.status.should == 200
      end
    end
    
    context "cookie authentication" do
      it "should run app if cookie signature is valid" do
        app = mock('rack app')
        app.should_receive(:call).with(instance_of(Hash)).and_return(response_env)
        
        cookie_request app, sign_cookies("#{API_KEY}_user" => "22", "#{API_KEY}_ss" => "SEKRIT")
        response.status.should == 200
      end
      
      it "should not run app if cookie signature turns out invalid" do
        cookie_request mock('rack app'), API_KEY => "INVALID", "#{API_KEY}_ss" => "SEKRIT"
        response.status.should == 400
      end
    end
  end

  describe 'with a block' do
    describe 'when the block returns a value that evaluates to true' do
      it 'should execute the middleware'
    end
    describe 'when the block returns a value that evaluates to false' do
      it 'should skip the middleware'
    end
  end
end
