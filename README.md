# Active Queryable

A light and simple gem for sorting / filtering / paginating a model in Rails.

## Installation

Simply add the gem to your Gemfile

```ruby
  gem 'active_queryable', github: 'monade/active_queryable'
```

or alternatively `bundle add active_queryable`

## Usage

```ruby
  class Person < ActiveModel::Base
    # Add this line to enable the gem
    as_queryable

    has_many :articles

    # Configure order and filters
    queryable order: { name: :asc },
              # Name filter is implicit, others will search for a scope
              filters: [:name, :name_like, :article_title]

    scope :of_name_like, ->(name) { where('name LIKE ?', "%#{name}%") }
    scope :of_article_title, ->(title) { joins(:articles).where(articles: { title: title }) }
  end
```

Let's query!
```ruby
  Person.query_by(filters: { name: 'john'}) # SELECT * FROM people WHERE people.name = 'john'
  Person.query_by(filters: { name_like: 'john', article_title: 'some article' }) # SELECT * FROM people INNER JOIN articles ON articles.person_id = people.id WHERE people.name LIKE 'john' AND article.title = 'some article'
  Person.query_by(order: '-name') # SELECT * FROM people ORDER BY name DESC
```

It also handles pagination, using kaminari!
```ruby
  Person.query_by(per: 20, page: 2) # SELECT * FROM people LIMIT 20 OFFSET 20
  # Accepts also JSON:API-styled parameters
  Person.query_by(page: { number: 2, size: 20 }) # SELECT * FROM people LIMIT 20 OFFSET 20
```
