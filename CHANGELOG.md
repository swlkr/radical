# Changelog
All notable changes to this project will be documented in this file

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

# [Unreleased]

# 1.0.1

- Fix changelog link in gemspec

## 1.0.0

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
