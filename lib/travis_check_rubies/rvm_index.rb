require_relative 'fetcher'

module TravisCheckRubies
  class RvmIndex
    URL = 'https://raw.githubusercontent.com/rvm/rvm/stable/config/known_strings'

    def version_strings
      TravisCheckRubies::Fetcher.new(URL).data.split("\n")
    end
  end
end
