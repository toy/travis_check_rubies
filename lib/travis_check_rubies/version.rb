require 'set'

require_relative 'rvm_index'
require_relative 'travis_index'

module TravisCheckRubies
  class Version
    class << self
      def convert(version_or_string)
        version_or_string.is_a?(self) ? version_or_string : new(version_or_string)
      end

      def available
        @available ||= [TravisIndex, RvmIndex].map(&:new).map(&:version_strings).inject(:|).map{ |s| new(s) }.sort
      end

      def update(version, parts: 0..2, allow_pre: false, intermediary: true, exclude: [], conservative: false)
        version = convert(version)
        return unless version.version_parts

        parts = Array(parts)
        exclude = exclude.map{ |ev| convert(ev) }
        ordered = allow_pre ? available : available.partition(&:pre).inject(:+)
        candidates = ordered.select do |v|
          next unless v.version_parts
          next unless v.match?(version, parts.min)
          next unless v >= version
          next if !allow_pre && v.pre && !version.pre
          next if exclude.any?{ |ev| ev.match?(v, ev.version_parts.length) }
          true
        end.reverse

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
          deduplicated = (update(version, **options) || [version]).select{ |v| has.add?(v) }
          updates[version] = [version] == deduplicated ? nil : deduplicated
        end

        Hash[versions.map{ |v| [v, updates[v]] }]
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
