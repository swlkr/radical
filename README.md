# radical

A rails inspired ruby web framework

# Learning

Check out the `examples/` folder for some ideas on how to get started and when  you're ready, check the `docs/` folder for more details.

# Quickstart

Create a directory with a `config.ru` and a `Gemfile` file inside of it

```sh
mkdir your_project
cd your_project
touch config.ru Gemfile
```

Put this inside of the `config.ru`

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

Install the gems and start the server

```sh
gem install radical puma
puma
```

Test it out

```sh
curl localhost:9292
# => /
```
