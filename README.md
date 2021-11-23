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
    plain '/'
  end
end

class App < Radical::App
  root Home
end

run App
```

__Install the gems and start the server__

```sh
gem install radical puma
puma
```

__Test it out__

```sh
curl localhost:9292
# => /
```
