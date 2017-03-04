require 'net/http'
require 'set'
require 'uri'
require 'yaml'

module TravisCheckRubies
  class Version
    class << self
      ROOT_URL = 'http://rubies.travis-ci.org/'

      def available
        @available ||= begin
          index_urls.select do |url|
            url.start_with?(base_url)
          end.map do |url|
            new(url[%r{([^/]+)\.tar\.(?:gz|bz2)$}, 1])
          end.sort
        end
      end

      def selected
        @selected ||= begin
          Array(YAML.load_file('.travis.yml')['rvm']).map do |string|
            new(string)
          end
        end
      end

      def matches(max_parts: 2)
        matches = {}
        deduplicate = Set.new
        available_versioned = available.select(&:version_parts).sort.reverse
        selected.select(&:version_parts).sort.reverse.each do |version|
          matches[version] = (0..max_parts).map do |n|
            available_versioned.find{ |v| version.match?(v, n) }
          end.reverse.select{ |v| deduplicate.add?(v) }
        end
        Hash[selected.map do |v|
          [v, [v] == matches[v] ? nil : matches[v]]
        end]
      end

    private

      def index_urls
        @index_urls ||= Net::HTTP.get(URI(ROOT_URL + 'index.txt')).split("\n")
      end

      def base_url
        @base_url ||= if ENV['TRAVIS']
          sys_path = `rvm debug`[/system:\s*"(.*?)"/, 1]
          "#{ROOT_URL}#{sys_path}/"
        else
          base_ubuntu_url = "#{ROOT_URL}ubuntu/"
          first_ubuntu_url = index_urls.sort.find{ |url| url.start_with?(base_ubuntu_url) }
          fail "First ubuntu url not fount out of:\n#{index_urls.join("\n")}" unless first_ubuntu_url
          first_ubuntu_url[%r{^.*/}]
        end
      end
    end

    include Comparable

    attr_reader :str, :type, :version_parts, :pre, :variant

    alias_method :to_s, :str

    alias_method :eql?, :==

    def initialize(str)
      str = "#{str}"
      @str = str.sub(/^ruby-/, '')
      @variant = $1 if str.slice!(/-(clang|railsexpress)$/)
      @type = str.slice!(/^([^0-9\-]+)-?/) ? $1 : 'ruby'
      version_str = $1 if str.slice!(/^(\d+(?:\.\d+)*(?:-p\d+)?)(\.|-|$)/)
      @version_parts = version_str.scan(/\d+/).map(&:to_i) if version_str
      @pre = str unless str.empty?
    end

    def <=>(other)
      other = self.class.new(other) unless other.is_a?(self.class)
      compare_by <=> other.compare_by
    end

    def hash
      str.hash
    end

    def match?(other, n)
      other = self.class.new(other) unless other.is_a?(self.class)
      match_by(n) == other.match_by(n)
    end

    def inspect
      "#<#{self.class.name} #{str}>"
    end

  protected

    def compare_by
      [
        type,
        version_parts || [],
        pre ? [0, pre] : [1],
        variant || '',
      ]
    end

    def match_by(n)
      [type, variant, version_parts.take(n)]
    end
  end
end
