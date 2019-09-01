require_relative 'fetcher'

module TravisCheckRubies
  class TravisIndex
    ROOT_URL = 'https://rubies.travis-ci.org/'

    def version_strings
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
      @base_url ||= if ENV['TRAVIS']
        sys_path = `rvm debug`[/(?:system|remote.path):\s*"(.*?)"/, 1]
        "#{ROOT_URL}#{sys_path}/"
      else
        base_ubuntu_url = "#{ROOT_URL}ubuntu/"
        first_ubuntu_url = index_urls.sort.find{ |url| url.start_with?(base_ubuntu_url) }
        fail "First ubuntu url (#{ROOT_URL}ubuntu/*) not fount out of:\n#{index_urls.join("\n")}" unless first_ubuntu_url
        first_ubuntu_url[%r{^.*/}]
      end
    end
  end
end
