# config for lograge
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.colorize_logging = false # 关闭彩色显示，会产生很多不适合阅读的字符。
  config.lograge.custom_options = lambda do |event|
    {
        uuid: event.payload[:uuid],
        session_id: event.payload[:session_id],
        type: 'request',
        host: event.payload[:host],
        remote_ip: event.payload[:remote_ip],
        origin: event.payload[:origin],
        user_agent: event.payload[:user_agent]
    }
  end
end

# for sql_log
# 先把默认的subscriber去掉。
Lograge.module_eval do
  ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
    case subscriber
    when ActiveRecord::LogSubscriber
      unsubscribe(:active_record, subscriber)
    end
  end
end

# 自己实现一个subscriber
module SQLLog
  class LogSubscriber < ActiveSupport::LogSubscriber
    IGNORE_PAYLOAD_NAMES = ["SCHEMA", "EXPLAIN"]

    def self.runtime=(value)
      ActiveRecord::RuntimeRegistry.sql_runtime = value
    end

    def self.runtime
      ActiveRecord::RuntimeRegistry.sql_runtime ||= 0
    end

    def self.reset_runtime
      rt, self.runtime = runtime, 0
      rt
    end

    def initialize
      super
    end

    def render_bind(column, value)
      if column
        if column.respond_to?(:binary?) && column.binary?
          # This specifically deals with the PG adapter that casts bytea columns into a Hash.
          value = value[:value] if value.is_a?(Hash)
          value = value ? "<#{value.bytesize} bytes of binary data>" : "<NULL binary data>"
        end

        [column.name, value]
      else
        [nil, value]
      end
    end

    def sql(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      payload = event.payload

      return if IGNORE_PAYLOAD_NAMES.include?(payload[:name])

      unless (payload[:binds] || []).empty?
        binds = "  " + payload[:binds].map { |col, v|
          render_bind(col, v)
        }.inspect
      end
      ids = Thread.current[:log_uuid_session_id] || Array.new(2)
      log = {
          name: payload[:name],
          duration: event.duration.round(1),
          binds: binds,
          message: payload[:sql],
          type: 'sql',
          uuid: ids[0],
          session_id: ids[1] }.to_json
      debug log
    end

    def logger
      ActiveRecord::Base.logger
    end
  end
end

# attach 到active_record上
SQLLog::LogSubscriber.attach_to :active_record

# remove log like [active_model_serializers] Rendered ActiveModel::Serializer::CollectionSerializer with ActiveModelSerializers::Adapter::JsonApi
require 'active_model_serializers'
ActiveSupport::Notifications.unsubscribe(ActiveModelSerializers::Logging::RENDER_EVENT)

# disable sql log tagging with [active_model_serializers]
ActiveModelSerializers.logger = Logger.new(STDOUT)
