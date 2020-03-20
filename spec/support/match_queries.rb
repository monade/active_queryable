def within_query
  $__instrumentation = ActiveSupport::Notifications.subscribe 'sql.active_record' do |_, _, _, _, data|
    yield data[:sql]
  end
end

def query_clear
  ActiveSupport::Notifications.unsubscribe($__instrumentation) if $__instrumentation
end
