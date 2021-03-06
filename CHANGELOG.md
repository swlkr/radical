# Changelog

All notable changes to this project will be documented in this file

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

# [Unreleased]

- **Breaking** Break app and routes and everything
- **Breaking** Change path helpers from `x_path` to `index_x_path` or `create_x_path` (they match the controller actions)
- Reload model after inserting/updating
- Somehow don't break anything but change models, controllers and views to generate with singular anyway
- Change convention to assume nothing about the plurality or case of controllers/models
- Add all column types to migrations
- Add unique, not null, check, and collate column options
- Render any view from any controller
- Fix update/insert when there aren't any columns
- Fix forms with model attributes in other controllers' views
- Add query logging
- Make many/one actually work
- Bring in shopify/tapioca gem
- Ignore modules in `Model#table_name`
- Add a bunch of convenience methods to the models/queries
- Terminate queries in a few methods, `all`, `group_by`, `each`, `first`, `last`
- Actually get layout working

# 1.2.0 (2021-12-17)

- *Breaking* Support only one level of nested resources, make them shallow only
- *Breaking* Move `db/migrations` to `migrations`
- *Breaking* Change `<%== f.button 'Save' %>` to `<%== f.submit 'Save' %>`
- *Breaking* Change the form helpers from `model[name]` to just `name`, it's cleaner.
- Add `Radical.env.[development?|production?|test?]`
- Add `_path` support for nested resource routes
- Add a random secret to the session cookie on startup
- Add asset concatention + compression (no minification yet)
- Remove dependence on rack-flash3
- Add security headers
- Add session configuration with `session` method in `App`
- Move all `_path` method definitions to `Radical::Controller`
- Add `exe/rad`
- Add `rad g mvc Todo(s) name:text done_at:integer` generators
- Add attrs to form helpers
- Add `rad g app` generator
- Add migrate/rollback `rad` commands

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
