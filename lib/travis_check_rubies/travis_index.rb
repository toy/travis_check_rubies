require_relative 'fetcher'

require 'travis_check_rubies/travis_yml'

module TravisCheckRubies
  class TravisIndex
    ROOT_URL = 'https://rubies.travis-ci.org/'

    LTS_VERSIONS = {
      precise: '12.04',
      trusty: '14.04',
      xenial: '16.04',
      bionic: '18.04',
      focal: '20.04',
    }

    def version_strings
      $stderr.puts "Using #{base_url}"
      index_urls.select do |url|
        url.start_with?(base_url)
      end.map do |url|
        url[%r{([^/]+)\.tar\.(?:gz|bz2)$}, 1]
      end
    end

  private

    def index_urls
      @index_urls ||= TravisCheckRubies::Fetcher.new(ROOT_URL + 'index.txt').data.split("\n")
    end

    def base_url
      @base_url ||= begin
        base_ubuntu_url = "#{ROOT_URL}ubuntu/"
        dist = TravisYml.new.dist
        version = LTS_VERSIONS[dist.to_sym]
        if version
          "#{base_ubuntu_url}#{version}/x86_64/"
        else
          fail "Unknown dist #{dist}"
        end
      end
    end
  end
end
