![Build Status](https://github.com/monade/active-queryable/actions/workflows/test.yml/badge.svg)
[![Gem Version](https://badge.fury.io/rb/active_queryable.svg)](https://badge.fury.io/rb/active_queryable)

# Active Queryable

Active Queryable is a lightweight Ruby gem designed to simplify sorting, filtering, and paginating models in Rails applications. Its intuitive API and seamless integration with ActiveModel make building complex queries a breeze.

## Features
* Easy integration with Rails models.
* Support for dynamic sorting, filtering, and pagination.
* Compatible with JSON:API specification for pagination parameters.
* Extensible through custom scopes for advanced filtering needs.


## Installation

Ensure you have Rails >= 5.2 (or specify another version if needed) and then add Active Queryable to your Gemfile:

```ruby
  gem 'active_queryable'
```

or alternatively `bundle add active_queryable`

## Usage

First, include the `as_queryable` method in your model to enable the gem.

```ruby
  class Person < ActiveModel::Base
    # Add this line to enable the gem
    as_queryable
  end
```


Then, configure the order and filters you want to use:

```ruby
  class Person < ActiveModel::Base
    # Add this line to enable the gem
    as_queryable

    # Configure order and filters
    queryable order: { name: :asc },
              filter: [:name]
  end
```

This will allow you to query your model using the `query_by` method:

```ruby
  Person.query_by(order: '-name') # SELECT * FROM people ORDER BY name DESC LIMIT 25
  Person.query_by(filter: { name: 'john'}) # SELECT * FROM people WHERE people.name = 'john' LIMIT 25
```

### Pagination
You can also use pagination, using [kaminari](https://github.com/kaminari/kaminari) under the hood:

```ruby
  Person.query_by(per: 20, page: 2) # SELECT * FROM people LIMIT 20 OFFSET 20
  # Accepts also JSON:API-styled parameters
  Person.query_by(page: { number: 2, size: 20 }) # SELECT * FROM people LIMIT 20 OFFSET 20
```

### Custom scopes and orders
You can also use custom scopes to extend the filtering and ordering capabilities.

The gem will look for a scope with the same name as the filter, and a method with the same name as the order.

```ruby
  class Person < ActiveModel::Base
    # Add this line to enable the gem
    as_queryable

    # Configure order and filters
    queryable order: { fullname: :asc },
              filter: [:name_like]

    # the `of_name_like` scope will be used when filtering by `name_like`
    scope :of_name_like, ->(name) { where('name LIKE ?', "%#{name}%") }
    # the `by_name` method will be used when ordering by `name`
    order :by_name, ->(direction) { order(firstname: direction, lastname: direction) }
  end
```

About Monade
----------------

![monade](https://monade.io/wp-content/uploads/2023/02/logo-monade.svg)

active_queryable is maintained by [mònade srl](https://monade.io).

We <3 open source software. [Contact us](https://monade.io/en/contact-us/) for your next project!
