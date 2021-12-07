# Routing

Routing in radical only happens via resource routing.

Resource routing is an abstraction on top of http routes popularized by rails and used in this project too.

Instead of thinking about your routes like `GET /login`, `POST /login` and `POST /logout` you think of them like "resources":

`GET /login` => `GET /session/new`

`POST /login` => `POST /session`

`POST /logout` => `DELETE /session`

The same thing works for "signup":

`GET /signup` => `GET /users/new`

`POST /signup` => `POST /users`

There are only ever 7 resource routes for any resource:

| action | url | description |
| --- | --- | --- |
| index | GET / | Show a list of things |
| show | GET /:id | Show one thing |
| new | GET /new | Show a form to create a new a thing |
| create | POST / | Create a new thing and redirect usually |
| edit | GET /:id/edit | Show a form to edit a thing |
| update | PATCH or PUT /:id | Submit the edit form and update the thing |
| destroy | DELETE /:id | Delete a thing |

# Differences from rails

If you're coming from rails:

- There is no converting from singular/plural convention
- There is also no converting from camel case to/from snake case
- The `_path` methods are exactly what you would expect

Here's an example:

```rb
require 'radical'

class Home < Radical::Controller
  def index; end # => home_path
end

class Todos < Radical::Controller
  def index; end # => todos_path
end

class Session < Radical::Controller
  def index; end # => session_path
end

class App
  root :Home # => Resolves to "/" instead of controller name
  resources :Todos # => resolves to /todos, /todos/new, /todos/:id, /todos/:id/edit
  resource :Session # => resolves to /session, /session/new, /session/edit
  resources :Item # => resolves to /item, /item/new, /item/:id, /item/:id/edit
end
```
