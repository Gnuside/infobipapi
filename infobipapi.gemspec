# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'infobipapi/version'

Gem::Specification.new do |spec|
  spec.name          = "infobipApi"
  spec.version       = InfobipApi::VERSION
  spec.authors       = ["Roland Laurès"]
  spec.email         = [ "roland.laures@netcat.io"]
  spec.description   = %q{InfobipApi Ruby client library}
  spec.summary       = %q{InfobipApi Ruby client library}
  spec.homepage      = "https://github.com/Gnuside/infobipapi"
  spec.license       = "Apache"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pry-coolline"
  spec.add_development_dependency "pry"
end
