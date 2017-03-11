require 'yaml'
require 'travis_check_rubies/version'

module TravisCheckRubies
  class TravisYml
    attr_reader :path
    attr_reader :versions, :allow_failures_versions, :exclude_versions, :include_versions

    def initialize(path = '.travis.yml')
      @path = path

      yaml = YAML.load_file(path)
      @versions = Array(yaml['rvm']).map(&Version.method(:new))
      @allow_failures_versions = matrix_versions(yaml, 'allow_failures')
      @exclude_versions = matrix_versions(yaml, 'exclude')
      @include_versions = matrix_versions(yaml, 'include')
    end

    def suggestions(options)
      suggestions = Hash.new{ |h, k| h[k] = [] }

      updates = Version.updates(versions, options)

      versions.each do |version|
        next unless (for_version = updates[version])
        suggestions['rvm'] << "#{version} -> #{for_version.join(', ')}"
      end

      allow_failures_versions.each do |version|
        next if versions.include?(version)
        next if include_versions.include?(version)
        suggestions['matrix.allow_failures'] << "#{version} in matrix.allow_failures is not in rvm or include list"
      end

      exclude_versions.each do |version|
        next if versions.include?(version)
        suggestions['matrix.exclude'] << "#{version} in matrix.exclude is not in rvm list"
      end

      {
        'matrix.allow_failures' => allow_failures_versions,
        'matrix.exclude' => exclude_versions,
      }.each do |section, versions|
        versions.each do |version|
          next unless (for_version = updates[version])
          suggestions[section] << "#{version} -> #{for_version.join(', ')}"
        end
      end

      include_versions.each do |version|
        next unless (for_version = Version.update(version, options))
        next if for_version.include?(version)
        suggestions['matrix.include'] << "#{version} -> #{for_version.join(', ')}"
      end

      return if suggestions.empty?
      suggestions.map do |section, lines|
        "#{section}:\n#{lines.map{ |line| "  #{line}" }.join("\n")}"
      end.join("\n")
    end

  private

    def matrix_versions(yaml, key)
      return [] unless (matrix = yaml['matrix'])
      return [] unless (list = matrix[key])
      Array(list).map{ |attrs| attrs['rvm'] }.compact.map(&Version.method(:new))
    end
  end
end
