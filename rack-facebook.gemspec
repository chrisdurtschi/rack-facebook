Gem::Specification.new do |s|
  s.name     = "rack-facebook"
  s.version  = "0.0.2"
  s.date     = "2009-01-09"
  s.summary  = "Rack middleware to verify and parse Facebook parameters"
  s.email    = "carlos@evolve.st"
  s.homepage = "http://www.evolve.st/notebook/2009/1/9/rack-facebook-a-new-rack-middleware-to-parse-facebook-parameters"
  s.description = "rack-facebook is a Rack middleware that checks the signature of Facebook params, and converts them to Ruby objects when appropiate. Also, it converts the request method from the Facebook POST to the original HTTP method used by the client."
  s.has_rdoc = true
  s.authors  = ["Carlos Paramio", "Christopher Durtschi"]
  s.files    = [
		"README.markdown", 
		"Rakefile", 
		"rack-facebook.gemspec", 
		"lib/rack/facebook/original_verifier.rb",
		"lib/rack/facebook/new_verifier.rb"]
  s.test_files = ["spec/spec_helper.rb", "spec/rack/facebook/original_verifier_spec.rb", "spec/rack/facebook/new_verifier_spec.rb"]
  s.rdoc_options = ["--main", "Rack::Facebook"]
  #s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.add_dependency("rack", [">= 0.4.0"])
end
