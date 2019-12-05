
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "reso_transport/version"

Gem::Specification.new do |spec|
  spec.name          = "reso_transport"
  spec.version       = ResoTransport::VERSION
  spec.authors       = ["Jon Druse"]
  spec.email         = ["jon@wrstudios.com"]

  spec.summary       = "A utility for consuming RESO Web API connections"
  spec.description   = "Supports Trestle, Spark, Bridge Interactive, MLS Grid"
  spec.homepage      = "http://github.com/wrstudios/reso_transport"
  spec.license       = "MIT"


  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 0.17.0"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-rg", "~> 5.0"
  spec.add_development_dependency "vcr", "~> 5.0"
  spec.add_development_dependency "byebug"
end
