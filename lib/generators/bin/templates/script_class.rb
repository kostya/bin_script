class <%= class_name %>Script < BinScript
  # You can define script parameters this way:
  # {type} {key}, {options}
  #
  # Availible types: noarg, optional and required
  # Key is the Symbol with parameter key
  # Options is a hash that may contain this keys:
  #   :description - parameters descriptions to automatic prepare usage message
  #   :alias       - symbol or array of symbols with aliases for this parameters
  #   :default     - default value for this parameter
  #
  # Instead of options hash you can use just string with description.
  #
  # Some examples:
  # noarg    :n,  "This is a parameter without argument. 'params(:n)' in script will return true or false."
  # optional :o,  :description => "Optional parameter that can has argument. 'params()'"
  # optional :oo, :description => "Optional parameter with default value and aliases. 'params(:o)' and 'params(:oo)' will return argument value or default key value", :default => "some default value", :alias => :oo
  # required :r,  :description => "Required argemtn. Script will exit if you use this parameter without argument value. Also you can use multiple aliases.", :alias => [:rr, :rrr]
  #
  # You may override default log level (Logger::INFO) for this script log this way:
  # self.log_level = Logger::INFO
  #
  # Availible log levels:
  #   DEBUG	=	0
  #   INFO	=	1
  #   WARN	=	2
  #   ERROR	=	3
  #   FATAL	=	4
  #   UNKNOWN	=	5
  #
  # By default, each bin logging into main log. Possible to specify log name for date.
  # Examples: "_%Y-%m-%d_%H-%M-%S" - each execute, new log
  #           "_%Y-%m-%d"          - each day, new log
  # self.date_log_postfix = "_%Y-%m-%d"

  # Execute
  def do!
    logger.info "Script <%= class_name %> works!"
  end
  
end