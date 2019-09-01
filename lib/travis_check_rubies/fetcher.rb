require 'digest'
require 'fspath'
require 'net/http'
require 'uri'

module TravisCheckRubies
  class Fetcher
    CACHE_TIME = 24 * 60 * 60

    attr_reader :url

    def initialize(url)
      @url = url
    end

    def data
      cached_data || fetch_data
    end

  private

    def cache_path
      @cache_path ||= FSPath(ENV['XDG_CACHE_HOME'] || '~/.cache').expand_path / "travis_check_rubies.#{Digest::SHA1.hexdigest url}"
    end

    def cached_data
      return unless cache_path.size?
      return unless cache_path.mtime + CACHE_TIME > Time.now
      cache_path.read
    end

    def fetch_data
      data = Net::HTTP.get(URI(url))

      cache_path.dirname.mkpath
      FSPath.temp_file('travis_check_rubies', cache_path.dirname) do |f|
        f.write(data)
        f.path.rename(cache_path)
      end

      data
    end
  end
end
