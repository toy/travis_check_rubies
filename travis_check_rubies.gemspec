# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'travis_check_rubies'
  s.version     = '0.6.0'
  s.summary     = 'Are you using the latest rubies in .travis.yml?'
  s.description = 'Check if `.travis.yml` specifies latest available rubies from listed on https://rubies.travis-ci.org and propose changes'
  s.homepage    = "https://github.com/toy/#{s.name}"
  s.authors     = ['Ivan Kuchin']
  s.license     = 'MIT'

  s.metadata = {
    'bug_tracker_uri'   => "https://github.com/toy/#{s.name}/issues",
    'documentation_uri' => "https://www.rubydoc.info/gems/#{s.name}/#{s.version}",
    'source_code_uri'   => "https://github.com/toy/#{s.name}",
  }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]

  s.required_ruby_version = '>= 2.3.0'

  s.add_runtime_dependency 'fspath', '~> 3.0'
  s.add_runtime_dependency 'psych', '~> 3.0'

  s.add_development_dependency 'rspec', '~> 3.0'
end
