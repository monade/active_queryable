
namespace :gem do
  task :release do
    desc 'Releases the gem'

    filename = `gem build active_queryable.gemspec 2> /dev/null | grep -E 'File:'`.split(' ').last
    `gem push #{filename}`
  end
end
