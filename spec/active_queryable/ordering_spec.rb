require 'spec_helper'

describe 'Ordering' do
  it 'default order' do
    query = Person.query_by(per: 'all')
    expect(query.to_sql).to include('ORDER BY "people"."name" ASC')
  end

  it 'order by column' do
    query = Person.query_by(sort: '-name', per: 'all')
    expect(query.to_sql).to include('ORDER BY "people"."name" DESC')
  end

  it 'order by scope' do
    query = Person.query_by(sort: '-article_title', per: 'all')
    expect(query.to_sql).to include('ORDER BY "articles"."title" DESC')
  end
end
