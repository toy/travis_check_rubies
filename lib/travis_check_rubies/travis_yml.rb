require 'fspath'
require 'yaml'
require 'travis_check_rubies/updater'
require 'travis_check_rubies/version'

module TravisCheckRubies
  class TravisYml
    Suggestion = Struct.new(:section, :from, :choices, :to)

    attr_reader :path, :options

    def initialize(path: '.travis.yml', options: {})
      @path = FSPath(path)
      @options = options
    end

    def warnings
      return @warnings if @warnings

      @warnings = []

      rvm_versions.group_by(&:itself).select{ |_, versions| versions.count > 1 }.each do |version, _|
        @warnings << "#{version} in rvm is repeating"
      end

      (allow_failures_versions - rvm_versions - include_versions).each do |version|
        @warnings << "#{version} in matrix.allow_failures is not in rvm or include list"
      end

      (exclude_versions - rvm_versions).each do |version|
        @warnings << "#{version} in matrix.exclude is not in rvm list"
      end

      @warnings
    end

    def suggestions
      return @suggestions if @suggestions

      @suggestions = []

      updates = Version.updates(rvm_versions, options)
      rvm_versions.each do |version|
        next unless (suggestions = updates[version])
        @suggestions << Suggestion.new('rvm', version, suggestions)
      end

      {
        'allow_failures' => allow_failures_versions,
        'exclude' => exclude_versions,
        'include' => include_versions,
      }.each do |section, versions|
        versions.each do |version|
          next unless (suggestions = Version.update(version, options))
          next if suggestions.include?(version)
          to = section == 'include' ? suggestions.last : suggestions.first
          @suggestions << Suggestion.new(section, version, suggestions, to)
        end
      end

      @suggestions
    end

    def suggest
      puts warnings

      suggestions.group_by(&:section).each do |section, section_suggestions|
        puts "#{section}:"
        section_suggestions.each do |suggestion|
          puts "  #{suggestion.from} -> #{suggestion.choices.join(', ')}"
        end
      end

      warnings.empty? && suggestions.empty?
    end

    def update
      unless warnings.empty?
        puts warnings

        return false
      end

      unless YAML.load(updated_content) == expected_object
        puts updated_content

        return false
      end

      FSPath.temp_file(path.basename, path.dirname) do |f|
        f.write(updated_content)
        f.path.rename(path)
      end

      true
    end

  private

    def original_content
      @original_content ||= path.read
    end

    def original_object
      @original_object ||= YAML.load(original_content)
    end

    def expected_object
      @expected_object ||= YAML.load(original_content).tap do |expected|
        suggestions.each do |suggestion|
          if suggestion.section == 'rvm'
            index = expected['rvm'].find_index{ |v| suggestion.from == v }
            expected['rvm'][index, 1] = suggestion.choices.map(&:to_s)
          else
            entry = expected['matrix'][suggestion.section].find{ |attrs| suggestion.from == attrs['rvm'] }
            entry['rvm'] = suggestion.to.to_s
          end
        end
      end
    end

    def updated_content
      return @updated_content if @updated_content

      updater = Updater.new(original_content)

      suggestions.each do |suggestion|
        updater = updater.apply_suggestion(suggestion)
      end

      @updated_content = updater.content
    end

    def rvm_versions
      @rvm_versions ||= Array(original_object['rvm']).map(&Version.method(:new))
    end

    def allow_failures_versions
      @allow_failures_versions ||= matrix_versions(original_object, 'allow_failures')
    end

    def exclude_versions
      @exclude_versions ||= matrix_versions(original_object, 'exclude')
    end

    def include_versions
      @include_versions ||= matrix_versions(original_object, 'include')
    end

    def matrix_versions(yaml, key)
      return [] unless (matrix = yaml['matrix'])
      return [] unless (list = matrix[key])
      Array(list).map{ |attrs| attrs['rvm'] }.compact.map(&Version.method(:new))
    end
  end
end
