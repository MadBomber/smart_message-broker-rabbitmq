# encoding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'smart_message'
require_relative "./lib/smart_message/broker/rabbitmq/version"

Gem::Specification.new do |spec|
  spec.name          = "smart_message-broker-rabbitmq"
  spec.version       = SmartMessage::Broker::Rabbitmq::VERSION
  spec.authors       = ["Dewayne VanHoozer"]
  spec.email         = ["dvanhoozer@gmail.com"]

  spec.summary       = %q{RabbitMQ broker pluging to SmartMessage.}
  spec.description   = %q{RabbitMQ broker pluging to SmartMessage.}
  spec.homepage      = "https://github.com/MadBomber/smart_message-broker-rabbitmq"


  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  # spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bunny"
  spec.add_dependency "nenv"
  spec.add_dependency "smart_message"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "debug_me"
  spec.add_development_dependency "minitest-power_assert"
  spec.add_development_dependency "shoulda"




end
