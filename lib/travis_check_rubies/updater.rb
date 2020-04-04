require 'psych'

module TravisCheckRubies
  class Updater
    attr_reader :content

    def initialize(content)
      @content = content
    end

    def apply_suggestion(suggestion)
      lines = content.lines

      if suggestion.section == 'rvm'
        apply_rvm_suggestion(lines, suggestion)
      else
        apply_matrix_suggestion(lines, suggestion)
      end

      self.class.new lines.join('')
    end

  private

    def apply_rvm_suggestion(lines, suggestion)
      node = rvm_node.children.find{ |node| suggestion.from == node.to_ruby }

      lines[node.start_line] = suggestion.choices.map do |version|
        log_change suggestion.from, version, 'rvm'
        line_with_version_change(lines, node, suggestion.from, version)
      end.join('')
    end

    def apply_matrix_suggestion(lines, suggestion)
      section_node = matrix_section_node(suggestion.section)

      entry_node = section_node.children.find{ |node| suggestion.from == node.to_ruby['rvm'] }

      node = fetch_node_mapping(entry_node, 'rvm')

      log_change suggestion.from, suggestion.to, 'matrix'
      lines[node.start_line] = line_with_version_change(lines, node, suggestion.from, suggestion.to)
    end

    def log_change(from, to, section)
      puts "#{from} -> #{to} \# #{section} section"
    end

    def root
      @root ||= Psych::Parser.new(Psych::TreeBuilder.new).parse(content).handler.root.children[0].children[0]
    end

    def rvm_node
      fetch_node_mapping(root, 'rvm').tap do |rvm_node|
        assert_type rvm_node, Psych::Nodes::Sequence
        fail "Expected block style: #{rvm_node.to_ruby}" unless rvm_node.style == Psych::Nodes::Sequence::BLOCK
      end
    end

    def matrix_section_node(section)
      matrix_node = fetch_node_mapping(root, 'matrix')

      fetch_node_mapping(matrix_node, section).tap do |section_node|
        assert_type section_node, Psych::Nodes::Sequence
      end
    end

    def fetch_node_mapping(mapping, key)
      assert_type mapping, Psych::Nodes::Mapping

      _, node = mapping.children.each_cons(2).find{ |key_node, _| key_node.to_ruby == key }

      fail "Didn't find key #{key.inspect} in #{mapping.to_ruby}" unless node

      node
    end

    def line_with_version_change(lines, node, from, to)
      assert_type node, Psych::Nodes::Scalar

      line = lines[node.start_line]

      before = line[0...node.start_column]
      excerpt = line[node.start_column...node.end_column]
      after = line[node.end_column..-1]

      fail "Didn't find #{from.to_s} in #{line}" unless excerpt.sub!(from.to_s, to.to_s)

      "#{before}#{excerpt}#{after}"
    end

    def assert_type(node, expected_class)
      return if node.is_a?(expected_class)

      fail "Expected a #{expected_class}, got #{node.class}"
    end
  end
end
