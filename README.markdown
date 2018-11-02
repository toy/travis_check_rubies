[![Gem Version](https://img.shields.io/gem/v/travis_check_rubies.svg?style=flat)](https://rubygems.org/gems/travis_check_rubies)
[![Build Status](https://img.shields.io/travis/toy/travis_check_rubies/master.svg?style=flat)](https://travis-ci.org/toy/travis_check_rubies)

# travis\_check\_rubies

Check if `.travis.yml` specifies latest available rubies from listed on https://rubies.travis-ci.org and propose changes.

## Gem installation

```sh
gem install travis_check_rubies
```

### Bundler

Add to your `Gemfile`:

```ruby
gem 'travis_check_rubies'
```

## Usage

### Travis CI

Merge into your `.travis.yml`:

```yaml
matrix:
  include:
    - env: CHECK_RUBIES=✓
      rvm: '2.4.0'
      script: bundle exec travis_check_rubies
```

### Locally

```sh
travis_check_rubies

bundle exec travis_check_rubies
```

## Copyright

Copyright (c) 2017-2018 Ivan Kuchin. See [LICENSE.txt](LICENSE.txt) for details.
