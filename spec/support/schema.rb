require 'active_record'

if ENV['ACTIVE_RECORD_ADAPTER'] == 'mysql'
  puts 'Running on MySQL...'
  ActiveRecord::Base.establish_connection(
    adapter: 'mysql2',
    host: ENV['DB_HOST'] || '127.0.0.1',
    username: ENV['DB_USERNAME'] || 'root',
    password: ENV['DB_PASSWORD'],
    database: 'acts_as_nosql'
  )
elsif ENV['ACTIVE_RECORD_ADAPTER'] == 'postgresql'
  puts 'Running on PostgreSQL...'
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    database: 'acts_as_nosql',
    host: ENV['DB_HOST'] || '127.0.0.1',
    username: ENV['DB_USERNAME'] || ENV['POSTGRES_USER'] || 'postgres',
    password: ENV['DB_PASSWORD'] || ENV['POSTGRES_PASSWORD']
  )
else
  puts 'Running on SQLite...'
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: ':memory:'
  )
end

class Common < ActiveRecord::Base
  self.abstract_class = true

  as_queryable
  queryable order: { name: :asc }, filter: ['name']
end

class Person < Common
  expand_queryable filter: ['email']
  expand_queryable filter: ['article_title']

  has_many :articles

  scope :of_article_title, ->(title) { joins(:articles).where(articles: { title: title }) }
  scope :by_article_title, ->(direction) { joins(:articles).order(:'articles.title' => direction) }

end


class Article < ActiveRecord::Base
  as_queryable
  queryable order: { title: :asc }, filter: ['title']

  scope :of_title, ->(title) { where('lower(title) = ?', title.downcase) }

  belongs_to :person
end

module Schema
  def self.create
    ActiveRecord::Migration.verbose = false

    ActiveRecord::Schema.define do
      create_table :people, force: true do |t|
        t.string   :name
        t.string   :email
        t.boolean  :terms_and_conditions, default: false
        t.timestamps null: false
      end

      create_table :articles, force: true do |t|
        t.integer  :person_id
        t.string   :title
        t.text     :body
        t.integer   :status
        t.timestamps null: false
      end
    end

    person = Person.create!(name: 'john doe', email: 'e@mail.com', terms_and_conditions: true)
    10.times do |i|
      article = Article.create!(person: person, title: "Some article #{i}", body: 'hello!', status: 0)
    end
  end
end
