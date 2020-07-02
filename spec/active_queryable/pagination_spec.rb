require 'spec_helper'

describe 'Pagination' do
  it 'paginates using `per` and `page`' do
    query = Article.query_by(per: 2, page: 2)
    expect(query.to_sql).to include('LIMIT 2 OFFSET 2')
  end

  it 'paginates using `page[number]` and `page[size]`' do
    query = Person.query_by(page: { number: 2, size: 2 })
    expect(query.to_sql).to include('LIMIT 2 OFFSET 2')
  end

  it 'accepts strings and numbers' do
    query = Person.query_by(page: { number: '2', size: '2' })
    expect(query.to_sql).to include('LIMIT 2 OFFSET 2')
  end

  it 'ignores invalid values of page' do
    query = Person.query_by(page: {}, per: 20)
    expect(query.to_sql).to include('LIMIT 20 OFFSET 0')
  end
end
