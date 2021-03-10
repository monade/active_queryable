require 'spec_helper'

describe 'Filters' do
  context 'default filters' do
    it 'applies column name-based filters' do
      query = Person.query_by(filter: { name: 'john doe', email: 'e@mail.com' }, per: 'all')
      expect(query.to_sql).to include('"people"."name" = \'john doe\'')
      expect(query.to_sql).to include('"people"."email" = \'e@mail.com\'')
      expect(query).to include(Person.first)
    end

    it 'applies id-exclusion filters' do
      query = Person.query_by(filter: { not: [1, 2] }, per: 'all')
      expect(query.to_sql).to include('NOT IN (1, 2)')
      expect(query).to be_empty
    end
  end

  it 'applies an explicit name filter' do
    query = Article.query_by(filter: { title: 'sOME ARTICLE 1' }, per: 'all')
    expect(query.to_sql).to include('lower(')
    expect(query).to include(Article.find_by_title!('Some article 1'))
  end

  it 'applies an explicit article title filter' do
    query = Person.query_by(filter: { article_title: 'Some article 1' }, per: 'all')
    expect(query.to_sql).to include('INNER JOIN "articles"')
    expect(query).to include(Person.first)
  end
end
