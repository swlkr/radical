# radical

__A rails inspired web framework__

## Quickstart

__Create a directory with a `config.ru` and a `Gemfile` file inside of it__

```sh
mkdir rad
cd rad
touch config.ru Gemfile
```

__Put this inside of the `config.ru`__

```rb
require 'radical'

class Home < Radical::Controller
  def index
    plain 'home#index'
  end
end

class App < Radical
  root Home
end

run App
```

__Put this inside of the Gemfile:__

```rb
source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'radical'
gem 'puma'
```

__Install the gems and start the server__

```sh
bundle
rackup
```

__Test it out___

```sh
curl localhost:9292
# => home#index
```
