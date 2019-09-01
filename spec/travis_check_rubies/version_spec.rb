require 'rspec'
require 'travis_check_rubies/version'

describe TravisCheckRubies::Version do
  def v(str)
    described_class.new(str)
  end

  def vs(strs)
    strs.map{ |str| described_class.new(str) }
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

    context 'for version without version parts' do
      let(:version){ v('ruby') }

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

  describe '.available' do
    it 'gets distinct sorted versions by combining indexes' do
      allow(TravisCheckRubies::TravisIndex).to receive(:new).and_return(double(version_strings: %w[e d c b a]))
      allow(TravisCheckRubies::RvmIndex).to receive(:new).and_return(double(version_strings: %w[d e f g h]))

      expect(described_class.available).to eq(vs(%w[a b c d e f g h]))
    end
  end

  describe '.update' do
    before do
      allow(described_class).to receive(:available).and_return(vs(available_strs).sort)
    end

    context 'for version without version parts' do
      let(:available_strs){ %w[ruby 1.2.3 2.3.4] }

      it{ expect(described_class.update(v('ruby'))).to eq nil }
    end

    context 'when there are no updates' do
      let(:available_strs){ %w[ruby 1.2.3 2.3.4] }

      it{ expect(described_class.update(v('2.3.4'))).to eq nil }
    end

    context 'when version is not present' do
      let(:available_strs){ %w[ruby 1.2.3 2.3.4] }

      it{ expect(described_class.update(v('3.4.5'))).to eq [] }
    end

    describe 'parts and intermediary' do
      let(:version){ v('1.7.1') }

      let(:available_strs){ %w[
        1.7.1 1.7.2  1.8.6 1.8.7  1.9.2 1.9.3
        2.0.8 2.0.9  2.1.6 2.1.7  2.2.4 2.2.5
        3.0.4 3.0.5  3.1.2 3.1.3  3.2.0 3.2.1
      ] }

      context 'when intermediary is true' do
        it 'returns all latest with distinct 0..2 (by default) matching version parts' do
          expect(described_class.update(version)).to eq vs(%w[1.7.2 1.8.7 1.9.3 2.0.9 2.1.7 2.2.5 3.0.5 3.1.3 3.2.1])
        end

        {
          0 => %w[3.2.1],
          0..1 => %w[1.9.3 2.2.5 3.2.1],
          0..2 => %w[1.7.2 1.8.7 1.9.3 2.0.9 2.1.7 2.2.5 3.0.5 3.1.3 3.2.1],
          1..2 => %w[1.7.2 1.8.7 1.9.3],
          2 => %w[1.7.2],
        }.each do |parts, expected|
          it "returns all latest with distinct #{parts} matching version parts" do
            expect(described_class.update(version, parts: parts)).to eq vs(expected)
          end
        end
      end

      context 'when intermediary is false' do
        it 'returns latest for each 0..2 (by default) matching version parts' do
          expect(described_class.update(version, intermediary: false)).to eq vs(%w[1.7.2 1.9.3 3.2.1])
        end

        {
          0 => %w[3.2.1],
          0..1 => %w[1.9.3 3.2.1],
          0..2 => %w[1.7.2 1.9.3 3.2.1],
          1..2 => %w[1.7.2 1.9.3],
          2 => %w[1.7.2],
        }.each do |parts, expected|
          it "returns latest for each #{parts} matching version parts" do
            expect(described_class.update(version, parts: parts, intermediary: false)).to eq vs(expected)
          end
        end
      end
    end

    describe 'pre releases' do
      let(:available_strs){ %w[2.4.0-pre 2.4.0 2.4.1 2.4.2-pre1 2.4.2-pre2 2.5.0 2.5.1-preview1 3.0.0-preview1] }

      context 'when allow_pre is false' do
        context 'for release version' do
          it 'returns only newer release versions' do
            expect(described_class.update(v('2.4.0'))).to eq vs(%w[2.4.1 2.5.0])
          end
        end

        context 'for pre release version' do
          context 'there are newer release versions' do
            it 'returns newer release versions' do
              expect(described_class.update(v('2.4.0-pre'))).to eq vs(%w[2.4.1 2.5.0 3.0.0-preview1])
            end
          end

          context 'there are no newer release versions' do
            it 'returns newer pre release versions' do
              expect(described_class.update(v('2.4.2-pre1'))).to eq vs(%w[2.4.2-pre2 2.5.0 3.0.0-preview1])
            end
          end
        end
      end

      context 'when allow_pre is true' do
        let(:expected){ vs(%w[2.4.2-pre2 2.5.1-preview1 3.0.0-preview1]) }

        context 'for release version' do
          it 'returns newer pre release versions' do
            expect(described_class.update(v('2.4.0'), allow_pre: true)).to eq expected
          end
        end

        context 'for pre release version' do
          context 'there are newer release versions' do
            it 'returns newer pre release versions' do
              expect(described_class.update(v('2.4.0-pre'), allow_pre: true)).to eq expected
            end
          end

          context 'there are no newer release versions' do
            it 'returns newer pre release versions' do
              expect(described_class.update(v('2.4.2-pre1'), allow_pre: true)).to eq expected
            end
          end
        end
      end
    end
  end

  describe '.updates' do
    before do
      allow(described_class).to receive(:available).
        and_return(vs(%w[1.8.7 1.9.3 2.0.9 2.1.7]).sort)
    end

    it 'returns a hash with updates for higher versions removed from updates for lower versions' do
      expect(described_class.updates(vs(%w[2.0.8 2.1.7 1.8.6 1.9.3])).to_a).
        to eq({
          v('2.0.8') => vs(%w[2.0.9]),
          v('2.1.7') => nil,
          v('1.8.6') => vs(%w[1.8.7]),
          v('1.9.3') => nil,
        }.to_a)
    end
  end
end
