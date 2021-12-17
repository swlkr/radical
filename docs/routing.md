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

# Prefixes

There are three ways to define routes:

1. `root`
2. `resource`
3. `resources`

`root` removes the name of the controller from the 7 resource routes
`resource` removes the `/:id` portion of the resource routes
`resources` gives you all 7 resource routes

```rb
class Routes < Radical::Routes
  root :A
  resource :B
  resources :C
end
```

The above code results in the following routes:

`root :A`

| action | url | description |
| --- | --- | --- |
| index | GET / | The home page |
| show | GET /:id | A prefix-less way to get params |
| new | GET /new | A prefix-less way to create new things? |
| create | POST / | A way to post to the home page |
| edit | GET /:id/edit | No prefix edit forms? |
| update | PATCH or PUT /:id | No prefix updates |
| destroy | DELETE /:id | No prefix deletes |

`resource :B`

| action | url | description |
| --- | --- | --- |
| index | GET /b | Show a list of things |
| new | GET /new | Show a form to create a new the thing |
| create | POST /b | Create a new thing and redirect usually |
| edit | GET /b/edit | Show a form to edit the thing |
| update | PATCH or PUT /b | Submit the edit form and update the thing |
| destroy | DELETE /b | Delete the thing |

`resources :C`

| action | url | description |
| --- | --- | --- |
| index | GET /c | Show a list of "c" |
| show | GET /c/:id | Show one "c" |
| new | GET /c/new | Show a form for creating a new "c" |
| create | POST /c | Create a new "c" |
| edit | GET /c/:id/edit | Show a form for editing a new "c" |
| update | PATCH or PUT /c/:id | Update an existing "c" |
| destroy | DELETE /c/:id | Delete a "c" |

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

class Routes < Radical::Routes
  root :Home # => Resolves to "/" instead of controller name
  resources :Todos # => resolves to /todos, /todos/new, /todos/:id, /todos/:id/edit
  resource :Session # => resolves to /session, /session/new, /session/edit
  resources :Item # => resolves to /item, /item/new, /item/:id, /item/:id/edit
end

class App
  routes Routes
end
```
