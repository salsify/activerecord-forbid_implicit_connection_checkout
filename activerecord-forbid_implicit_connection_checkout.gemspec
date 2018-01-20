# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record/forbid_implicit_connection_checkout/version'

Gem::Specification.new do |spec|
  spec.name          = 'activerecord-forbid_implicit_connection_checkout'
  spec.version       = ActiveRecord::ForbidImplicitConnectionCheckout::VERSION
  spec.authors       = ['Salsify, Inc']
  spec.email         = ['engineering@salsify.com']

  spec.summary       = 'Optionally prevents threads from checking out activerecord connections.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/salsify/activerecord-forbid_implicit_connection_checkout'

  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.1'

  # Set 'allowed_push_post' to control where this gem can be published.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.add_dependency 'activerecord', '>= 5', '< 5.2'
  spec.add_dependency 'activemodel', '>= 5', '< 5.2'
  spec.add_dependency 'activesupport', '>= 5', '< 5.2'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'salsify_rubocop', '~> 0.48.1'
  spec.add_development_dependency 'overcommit'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'pg', '~> 0.18'
  spec.add_development_dependency 'with_model'
end
