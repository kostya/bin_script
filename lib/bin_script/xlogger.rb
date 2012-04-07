# -*- encoding: utf-8 -*-
require 'logger'

class XLogger < Logger
  def initialize(hint = {})

    if(hint[:rotate])
      super(hint[:file] || STDOUT, hint[:rotate])
    else
      super(hint[:file] || STDOUT)
    end

    STDOUT.sync = true
    self.formatter = Formatter.new
    self.datetime_format = hint[:date_format] || "%d.%m %H:%M:%S"

    # Don't change default logger if asked
    if hint[:dont_touch_rails_logger].blank? && defined?(ActiveRecord::Base)
      ActiveRecord::Base.logger = self
      
      def Rails.logger
        ActiveRecord::Base.logger
      end
    end

    self.level = hint[:log_level] || rails_env_log_level
    log_sql if hint[:log_sql] || !prod_env?
  end

  class Formatter < Logger::Formatter
    def call(severity, time, progname, msg)
      if severity == 'INFO' && msg.nil?
        # use this if you want a simple blank line without date in your logs:
        # just call a logger.info without any params
        "\n"
      else
        format_datetime(time) << " " <<  msg2str(msg) << "\n"
      end
    end
  end

  def log_sql
    ActiveRecord::Base.connection.logger = self if defined?(ActiveRecord::Base)
  end

  def rails_env_log_level
    prod_env? ? Logger::INFO : Logger::DEBUG
  end
  
  def prod_env?
    defined?(Rails) && Rails.env.production?
  end
end

if defined?(ActiveRecord)
  module ActiveRecord
    module ConnectionAdapters
      class AbstractAdapter
        def logger=(val)
          @logger = val
        end
      end
    end
  end
end