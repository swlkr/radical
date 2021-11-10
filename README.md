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

class HomeController < Controller
  def index
    render plain: 'home#index'
  end
end

class App < Radical
  routes do
    get '/', to: 'home#index'
  end
end

run App.new
```

__Put this inside of the Gemfile:__

```rb
source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'radical'
gem 'puma'
```

__Install the gems__

```sh
bundle install
```

__Start the server__

```sh
rackup
```

__Test it out___

```sh
curl localhost:9292
# => home#index
```
