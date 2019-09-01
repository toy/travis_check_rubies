require 'rspec'
require 'travis_check_rubies/travis_index'

describe TravisCheckRubies::TravisIndex do
  describe '#base_url' do
    before do
      allow(ENV).to receive(:[]).with('TRAVIS').and_return(env_travis)
    end

    context 'when env variable TRAVIS is set' do
      let(:env_travis){ 'true' }

      it 'gets base_url from rvm debug' do

        allow(subject).to receive(:`).with('rvm debug').
          and_return(%Q{  foo: "xxx"  \n  system: "XXX/YYY"  \n  bar: "yyy"  })

        expect(subject.send(:base_url)).to eq('https://rubies.travis-ci.org/XXX/YYY/')
      end
    end

    context 'when env variable TRAVIS is not set' do
      let(:env_travis){ nil }

      it 'gets base_url from first ubuntu url in index' do
        allow(subject).to receive(:index_urls).and_return(%w[
          https://rubies.travis-ci.org/osx/AAA/1.tar.gz
          https://rubies.travis-ci.org/ubuntu/ZZZ/2.tar.gz
          https://rubies.travis-ci.org/ubuntu/BBB/3.tar.gz
        ])

        expect(subject.send(:base_url)).to eq('https://rubies.travis-ci.org/ubuntu/BBB/')
      end
    end
  end

  describe '#version_strings' do
    it 'gets versions from index urls matching base_url' do
      allow(subject).to receive(:index_urls).and_return(%w[
        https://rubies.travis-ci.org/osx/AAA/1.tar.gz
        https://rubies.travis-ci.org/ubuntu/ZZZ/2.tar.gz
        https://rubies.travis-ci.org/ubuntu/BBB/4.tar.gz
        https://rubies.travis-ci.org/ubuntu/BBB/3.tar.bz2
      ])
      allow(subject).to receive(:base_url).and_return('https://rubies.travis-ci.org/ubuntu/BBB/')

      expect(subject.version_strings).to match_array(%w[3 4])
    end
  end
end
