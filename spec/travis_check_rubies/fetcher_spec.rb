require 'rspec'
require 'travis_check_rubies/fetcher'

describe TravisCheckRubies::Fetcher do
  describe '#data' do
    subject{ described_class.new(url) }

    let(:url){ 'https://example.com/index.txt' }
    let(:cache_path){ FSPath.temp_file_path }

    before do
      allow(subject).to receive(:cache_path).and_return(cache_path)
    end

    it 'returns data from url' do
      allow(Net::HTTP).to receive(:get).with(URI(url)).
        and_return("one\ntwo\nthree")

      expect(subject.data).to eq("one\ntwo\nthree")
    end

    it 'caches result' do
      allow(Net::HTTP).to receive(:get).with(URI(url)).
        once.and_return("a\nb\nc")

      3.times{ expect(subject.data).to eq("a\nb\nc") }
    end

    it 'reads cache from file if it is new' do
      cache_path.write "foo\nbar"
      allow(cache_path).to receive(:size?).and_return(616)
      allow(cache_path).to receive(:mtime).and_return(Time.now - described_class::CACHE_TIME / 2)

      expect(Net::HTTP).not_to receive(:get)
      expect(subject.data).to eq("foo\nbar")
    end

    it 'writes cache file if it is stale' do
      allow(cache_path).to receive(:size?).and_return(616)
      allow(cache_path).to receive(:mtime).and_return(Time.now - described_class::CACHE_TIME * 2)
      allow(Net::HTTP).to receive(:get).with(URI(url)).
        once.and_return("brave\nnew\nworld")

      expect(subject.data).to eq("brave\nnew\nworld")
      expect(cache_path.read).to eq("brave\nnew\nworld")
    end
  end
end
