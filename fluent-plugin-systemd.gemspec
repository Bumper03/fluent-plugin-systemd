# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'fluent-plugin-systemd'
  spec.version       = '0.0.1'
  spec.authors       = ['Ed Robinson']
  spec.email         = ['ed@reevoo.com']

  spec.summary       = 'Input plugin to read from systemd journal.'
  spec.description   = 'This is a fluentd input plugin. It reads logs from the systemd journal.'
  spec.homepage      = 'https://github.com/assemblyline/fluent-plugin-systemd'
  spec.license       = 'MIT'


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(/^(test|spec|features)\//) }
  spec.executables   = spec.files.grep(/^exe\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.4'
  spec.add_development_dependency 'test-unit', '~> 3.1'
  spec.add_development_dependency 'reevoocop'

  spec.add_runtime_dependency 'fluentd', '~> 0.12'
  spec.add_runtime_dependency 'systemd-journal', '~> 1.2'
end
