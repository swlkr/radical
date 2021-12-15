# Changelog

All notable changes to this project will be documented in this file

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

# [Unreleased]

- Add `Radical.env.[development?|production?|test?]`
- Add `_path` support for nested resource routes
- Add a random secret to the session cookie on startup
- *Breaking* Support only one level of nested resources, make them shallow only
- Add asset concatention + compression (no minification yet)
- Remove dependence on rack-flash3
- Add security headers
- Add session configuration with `session` method in `App`
- Move all `_path` method definitions to `Radical::Controller`
- *Breaking* Move `db/migrations` to `migrations`
- Add basic generators
- *Breaking* Change `<%== f.button 'Save' %>` to `<%== f.submit 'Save' %>`
- Add attrs to form helpers

# 1.1.0 (2021-12-06)

- *Breaking* `root`, `resource` and `resources` methods no longer take class constants
- *Breaking* Move route class methods to `Routes` class instead of `App`
- *Breaking* Create migration class, use migration classes in migrate!
- *Breaking* Make routes take symbols or strings, not classes to better line up with models
- *Breaking* Move connection string handling to database
- Make everything use `frozen_string_literal`
- Purposefully never add callbacks, `before_action` or autoloading

# 1.0.2 (2021-12-02)

- Set default views / migrations paths

# 1.0.1 (2021-12-02)

- Fix changelog link in gemspec

# 1.0.0 (2021-12-01)

- Very basic understanding of how much memory it takes for a basic ruby app
- Start to integrate controllers and routing
- Add url params support to router
- Simple (not efficient) loop through routes and compare regex routing
- Bring in rack as a dependency in the gemspec
- Actually make everything work with rack for real
- Add an examples folder to test it out with real http requests!
- Add very simple ERB views
- Experiment with tilt
- Better view stuff, no tilt yet
- Use Rack::Request and Rack::Response
- Automatically render view from controller if a Rack::Response isn't returned
- Update tests
- Experiment with a module based mvc thing, didn't pan out
- Only allow resource routes, custom method names will not be found
- Add a bunch of rack middleware
- Move call to class
- Use Rack::Test
- Rename routes to resources; add resource method
- Add nested resources, multi-argument resources
- Use rack sessions, rack-csrf and rack-flash3
- Add naive migrations
- Add naive models
- Add naive form helper
