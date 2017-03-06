require 'net/http'
require 'set'
require 'uri'

module TravisCheckRubies
  class Version
    class << self
      ROOT_URL = 'http://rubies.travis-ci.org/'

      def convert(version_or_string)
        version_or_string.is_a?(self) ? version_or_string : new(version_or_string)
      end

      def available
        @available ||= begin
          index_urls.select do |url|
            url.start_with?(base_url)
          end.map do |url|
            new(url[%r{([^/]+)\.tar\.(?:gz|bz2)$}, 1])
          end.sort
        end
      end

      def update(version, parts: 0..2, allow_pre: false, intermediary: true)
        version = convert(version)
        return unless version.version_parts

        parts = Array(parts)
        ordered = allow_pre ? available : available.partition(&:pre).inject(:+)
        candidates = ordered.reverse.select do |v|
          v.version_parts && v.match?(version, parts.min) && v >= version
        end

        updates = if intermediary
          candidates.group_by do |v|
            v.version_parts.take(parts.max)
          end.flat_map do |_, group|
            parts.map do |n|
              group.find{ |v| v.match?(version, n) }
            end
          end
        else
          parts.map do |n|
            candidates.find{ |v| v.match?(version, n) }
          end
        end

        updates.compact!
        updates.uniq!
        updates.sort!

        updates unless [version] == updates
      end

      def updates(versions, **options)
        versions = versions.map{ |v| convert(v) }

        updates = {}
        has = Set.new
        versions.uniq.sort.reverse_each do |version|
          deduplicated = (update(version, options) || [version]).select{ |v| has.add?(v) }
          updates[version] = [version] == deduplicated ? nil : deduplicated
        end

        Hash[versions.map{ |v| [v, updates[v]] }]
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
      [type, variant, version_parts && version_parts.take(n)]
    end
  end
end
