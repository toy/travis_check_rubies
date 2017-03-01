require 'rspec'
require 'travis_check_rubies/version'

describe TravisCheckRubies::Version do
  def v(str)
    described_class.new(str)
  end

  def vs(strs)
    strs.map{ |str| described_class.new(str) }
  end

  def cleanup_instance_variables(o)
    o.instance_variables.each do |name|
      o.remove_instance_variable(name)
    end
  end

  describe 'parsing' do
    {
      '1.2.3-pre1' => {
        version_parts: [1, 2, 3],
        pre: 'pre1',
      },
      'jruby' => {
        type: 'jruby',
      },
      'ruby-2.3.4.5-clang' => {
        str: '2.3.4.5-clang',
        version_parts: [2, 3, 4, 5],
        variant: 'clang',
      },
      'xrb-1000' => {
        type: 'xrb',
        version_parts: [1000],
      },
      '1.5' => {
        version_parts: [1, 5],
      },
      '1.8.4-p616' => {
        version_parts: [1, 8, 4, 616],
      },
    }.each do |version_string, defined_attributes|
      context "of #{version_string}" do
        subject{ v(version_string) }

        let(:default_attributes) do
          {
            str: version_string,
            type: 'ruby',
            version_parts: nil,
            pre: nil,
            variant: nil,
          }
        end

        it{ is_expected.to have_attributes(default_attributes.merge(defined_attributes)) }
      end
    end
  end

  describe '#eql?' do
    it 'returns false for different version' do
      expect(v('1.8')).not_to eql(v('1.9'))
    end

    it 'returns true for equal versions' do
      expect(v('1.8')).to eql(v('1.8'))
    end

    it 'returns true for same version in different format' do
      expect(v('1.8')).to eql(v('ruby-1.8'))
    end

    it 'returns true for same version string' do
      expect(v('1.8')).to eql('1.8')
    end
  end

  describe '#<=>' do
    let(:versions) do
      vs(%w[
        jruby-head
        jruby-1.7.7
        jruby-1.7.26
        jruby-9.0.0.0.pre1
        jruby-9.0.0.0.pre2
        jruby-9.0.0.0
        ruby-1.8.7
        ruby-1.8.7-p371
        ruby-2.0.0-p645
        ruby-2.0.0-p647
        ruby-2.0.0-p647-clang
      ])
    end

    it 'oders versions using all parts' do
      expect(versions.reverse.sort).to eq(versions)
    end
  end

  describe '#match?' do
    subject{ v('ruby-1.7.7') }

    context 'for same version' do
      let(:version){ v('ruby-1.7.7') }

      it 'matches with any number of parts' do
        (0..4).each{ |n| is_expected.to be_match(version, n) }
      end
    end

    context 'for different patch version' do
      let(:version){ v('ruby-1.7.8') }

      it 'matches with 0..2 parts' do
        (0..2).each{ |n| is_expected.to be_match(version, n) }
      end

      it 'does not match with more parts' do
        (3..4).each{ |n| is_expected.not_to be_match(version, n) }
      end
    end

    context 'for different minor version' do
      let(:version){ v('ruby-1.8.7') }

      it 'matches with 0..1 parts' do
        (0..1).each{ |n| is_expected.to be_match(version, n) }
      end

      it 'does not match with more parts' do
        (2..4).each{ |n| is_expected.not_to be_match(version, n) }
      end
    end

    context 'for different major version' do
      let(:version){ v('ruby-2.7.7') }

      it 'matches with 0 parts' do
        is_expected.to be_match(version, 0)
      end

      it 'does not match with more parts' do
        (1..4).each{ |n| is_expected.not_to be_match(version, n) }
      end
    end

    context 'for version with additional part' do
      let(:version){ v('ruby-1.7.7.1') }

      it 'matches with 0..3 parts' do
        (0..3).each{ |n| is_expected.to be_match(version, n) }
      end

      it 'does not match with more parts' do
        is_expected.not_to be_match(version, 4)
      end
    end

    context 'for pre release of same version' do
      let(:version){ v('ruby-1.7.7-pre1') }

      it 'matches with any number of parts' do
        (0..4).each{ |n| is_expected.to be_match(version, n) }
      end
    end

    context 'for different type of same version' do
      let(:version){ v('jruby-1.7.7') }

      it 'does not match' do
        (0..4).each{ |n| is_expected.not_to be_match(version, n) }
      end
    end

    context 'for different variant of same version' do
      let(:version){ v('ruby-1.7.7-clang') }

      it 'does not match' do
        (0..4).each{ |n| is_expected.not_to be_match(version, n) }
      end
    end
  end

  describe '#inspect' do
    {
      '1.2.3-pre1' => '#<TravisCheckRubies::Version 1.2.3-pre1>',
      'jruby' => '#<TravisCheckRubies::Version jruby>',
    }.each do |version_string, inspect|
      context "for #{version_string}" do
        it{ expect(v(version_string).inspect).to eq(inspect) }
      end
    end
  end
end
