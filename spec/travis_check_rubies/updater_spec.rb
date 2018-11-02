require 'rspec'
require 'travis_check_rubies/updater'

describe TravisCheckRubies::Updater do
  describe '#apply_suggestion' do
    subject{ described_class.new(content).apply_suggestion(suggestion) }

    context 'for rvm change suggestion' do
      let(:content) do
        <<~YAML
          language: ruby
          rvm: # rvm
            - '2.1.3' # foo
            - '2.2.8' # bar
            - '2.5.0' # baz
          before_script:
            - env # env
        YAML
      end

      context 'removing version' do
        let(:suggestion){ double(section: 'rvm', from: '2.2.8', choices: []) }

        let(:expected) do
          <<~YAML
            language: ruby
            rvm: # rvm
              - '2.1.3' # foo
              - '2.5.0' # baz
            before_script:
              - env # env
          YAML
        end

        it{ is_expected.to have_attributes(content: expected) }
      end

      context 'changing to one version' do
        let(:suggestion){ double(section: 'rvm', from: '2.2.8', choices: [double(to_s: '2.2.9')]) }

        let(:expected) do
          <<~YAML
            language: ruby
            rvm: # rvm
              - '2.1.3' # foo
              - '2.2.9' # bar
              - '2.5.0' # baz
            before_script:
              - env # env
          YAML
        end

        it{ is_expected.to have_attributes(content: expected) }
      end

      context 'changing to multiple versions' do
        let(:suggestion){ double(section: 'rvm', from: '2.2.8', choices: [double(to_s: '2.2.9'), double(to_s: '2.3.4')]) }

        let(:expected) do
          <<~YAML
            language: ruby
            rvm: # rvm
              - '2.1.3' # foo
              - '2.2.9' # bar
              - '2.3.4' # bar
              - '2.5.0' # baz
            before_script:
              - env # env
          YAML
        end

        it{ is_expected.to have_attributes(content: expected) }
      end
    end

    context 'for matrix change suggestion' do
      let(:content) do
        <<~YAML
          language: ruby
          before_script:
            - env # env
          matrix:
            allow_failures:
              - rvm: '2.2.8' # foo
            exclude:
              - rvm: '2.2.8' # bar
            include:
              - rvm: '2.1.3' # foo
              - rvm: '2.2.8' # bar
              - rvm: '2.2.8' # baz
        YAML
      end

      let(:suggestion){ double(section: 'include', from: '2.2.8', to: double(to_s: '2.2.9')) }

      let(:expected) do
        <<~YAML
          language: ruby
          before_script:
            - env # env
          matrix:
            allow_failures:
              - rvm: '2.2.8' # foo
            exclude:
              - rvm: '2.2.8' # bar
            include:
              - rvm: '2.1.3' # foo
              - rvm: '2.2.9' # bar
              - rvm: '2.2.8' # baz
        YAML
      end

      it{ is_expected.to have_attributes(content: expected) }
    end
  end
end
