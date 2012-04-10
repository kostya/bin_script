# -*- encoding: utf-8 -*-
require 'getoptlong'
require 'pathname'

require File.dirname(__FILE__) + '/rails_stub'
require File.dirname(__FILE__) + '/lock_file'
require File.dirname(__FILE__) + '/xlogger'
require File.dirname(__FILE__) + '/class_inheritable_attributes'
#require 'active_support/core_ext/class/attribute.rb'

class BinScript
  include ClassLevelInheritableAttributes
  class_inheritable_attributes :parameters, :log_level, :enable_locking, :enable_logging, :date_log_postfix, :disable_puts_for_tests, :description
  
  # Default parameters
  @parameters = [
      {:key => :e, :type => :required, :description => "Rails environment ID (default - development)"},
      {:key => :h, :type => :noarg,    :description => "Print usage message", :alias => [:H, :help]},
      {:key => :l, :type => :required, :description => "Path to log file (default \#{Rails.root}/log/[script_name].log)"},
      {:key => :L, :type => :required, :description => "Path to lock file (default \#{Rails.root}/locks/[script_name].lock)"}
  ]

  # Enable locking by default
  @enable_locking = true

  # Enable logging by default
  @enable_logging = true
  
  # Default log level INFO or DEBUG for test env
  @log_level = (RailsStub.env == 'development' ? XLogger::DEBUG : XLogger::INFO)
  
  # Bin Description
  @description = nil

  # By default, each bin logging into main log. Possible to specify log name for date.
  # Examples: "_%Y-%m-%d_%H-%M-%S" - each execute, new log
  #           "_%Y-%m-%d"          - each day, new log
  @date_log_postfix = ''

  # BinScript can output with puts, for specs puts is not good, this option disable puts in test env
  @disable_puts_for_tests = false

  # Allowed parameter types. Equivalence aliases with GetoptLong constants.
  PARAMETER_TYPES = {
    :noarg     => GetoptLong::NO_ARGUMENT,
    :optional  => GetoptLong::OPTIONAL_ARGUMENT,
    :required  => GetoptLong::REQUIRED_ARGUMENT
  }

  # Place for logger object
  attr_accessor :logger

  # Place for store exit status.
  attr_accessor :exit_status

  # Create shortcuts to simplify logging from scripts
  singleton = (class << self; self end)
  Logger::Severity.constants.each do |level|
    method = level.to_s.downcase

    # Define class level helper method
    singleton.class_eval do
      define_method :info do |message|
        return unless RailsStub.logger
        RailsStub.logger.send(method,message)
      end
    end

    # Define instance level helper method
    define_method method do |message|
      return unless @logger
      @logger.send(method,message)
    end
  end
  
  class << self
    # Get parameter by key
    def get_parameter(key)
      param = @parameters.find{|p| p[:key] == key || (p[:alias].present? && p[:alias].include?(key))}
      raise "Can't find parameter with key #{key.inspect} for class #{self.inspect}!" if param.nil?
      param
    end

    # Prepare readable script name
    def script_name
      self.to_s.underscore.gsub('/','__')
    end
    
    def bin_name
      script_name.gsub('_script', '')
    end

    # Parse script filename. Extract important path parts
    def parse_script_file_name(filename)
      result = {}
      # Prepare important parts of source script filename
      parts = filename.split(File::SEPARATOR)
      parts = parts[parts.index('bin')+1..-1]
      parts.map!{|p| File.basename(p).split('.').first}

      result[:parts] = parts

      result[:class] = calculate_script_class_name(parts)
      result[:files]  = calculate_script_class_filename(parts)

      result
    end

    # Prepare class name from filename parts
    def calculate_script_class_name(parts)
      # Calculate class name and paths from source script filename parts
      if(parts.length > 1)
        class_name = parts.map{|p| p.camelize}.join('::') + parts.first.camelize
      else
        class_name = parts.first.camelize
      end
      class_name += "Script"
    end

    # Prepare class name from filename parts
    def calculate_script_class_filename(parts)
      files = []

      # Calculate and add to list file with script class itself
      class_file = File.join(%w{app models bin}, parts)
      class_file += '_nagios' if(parts.length > 1)
      class_file += '_script.rb'
      files << class_file

      # Add intermediate classes
      parts[0..-2].each { |p| files << "app/models/#{p}_script.rb" }

      files.reverse
    end
    
    def load_env
      unless defined?(NO_RAILS)
        # Load rails envoronment if not yet and we need it
        file = File.join(RailsStub.root, %w{config environment})
        require file
      else
        require 'active_support'
      end    
    end

    # Run script detected by the filename of source script file
    def run_script(filename = $0)
      cfg = parse_script_file_name(Pathname.new(filename).realpath.to_s)
      cfg[:files].each { |f| require File.join(RailsStub.root, f) }

      # Create instance and call run! for script class
      klass = cfg[:class].constantize
      script = klass.new
      script.run!

      # Exit with specified exit status
      exit script.exit_status || 0
    end

    # Prepare aliases for adding parameters in child classes
    PARAMETER_TYPES.keys.each do |type|
      define_method type do |key, opts|
        param = {:key => key, :type => type}
        if opts.is_a?(String)
          param[:description] = opts
        else
          param = param.merge(opts)
        end

        # We want aliases always to be an array
        param[:alias] = [param[:alias]].flatten.compact

        @parameters = @parameters + [param]
      end
    end

    # Remove parameter
    def remove_parameter(key)
      new = []
      @parameters.each { |p| new << p if p[:key] != key }
      @parameters = new
    end
    
    # Prepare ARGV parameters as hash
    def get_argv_values
      values = {}
      o = GetoptLong.new(*get_getoptlong_params)
      o.quiet = true   # Don't write arg error to STDERR
      o.each { |opt, arg| values[opt[1..-1].to_sym] = arg }
      values
    end

    # Prepare usage message
    def usage(message = nil)
      usage_msg = ''
      usage_msg += "Error: #{message}\n\n" unless message.nil?
      usage_msg += "Use: ./bin/#{bin_name}.rb [OPTIONS]\n\n"
      usage_msg += "\"#{self.description}\"\n\n" if message.nil? && self.description.present?
      usage_msg += "Availible options:\n\n"
      
      @parameters.each do |param|
        arg = case param[:type]
          when :required then " v "
          when :optional then "[v]"
          when :noarg    then "   "
        end
        usage_msg += "  #{prefix_key param[:key]}#{arg} #{param[:description]}\n"
      end
      usage_msg += "\n"
      usage_msg
    end

    private
    # Prepare parameters in Getoptlong lib format
    def get_getoptlong_params
      result = []
      @parameters.each do |param|
        cfg = [prefix_key(param[:key])]
        param[:alias].each{|als| cfg << prefix_key(als) } unless param[:alias].blank?
        cfg << PARAMETER_TYPES[param[:type]]
        result << cfg
      end
      result
    end

    # Prepare argument name with short or long prefix
    def prefix_key(key)
      key = key.to_s
      (key.length > 1 ? "--" : "-") + key
    end
  end

  def puts(*arg)
    return if self.class.disable_puts_for_tests && RailsStub.env == 'test'
    Kernel.puts(*arg)
  end

  # Initialize script
  def initialize
    begin
      @source_argv = ARGV.dup
      @overrided_parameters = {}
      @params_values = (RailsStub.env == 'test' ? {} : self.class.get_argv_values)

      # Create logger if logging enabled
      if self.class.enable_logging
        @logger = XLogger.new(:file => log_filename, :dont_touch_rails_logger => (RailsStub.env == 'test'))
        @logger.level = self.class.log_level
      end

    rescue GetoptLong::InvalidOption, GetoptLong::MissingArgument, GetoptLong::NeedlessArgument => e
      usage_exit e.message
    end
  end
  
  def check_required_params
    self.class.parameters.each do |param|
      if param[:type] == :required && @params_values.has_key?(param[:key])
        if @params_values[param[:key]].nil?
          error "Param #{param[:key]} require value, but not present"
          usage_exit
        end
      end
    end
  end

  # Create lock file, call script code and unlock file even if error happend.
  def run!

    # Print usage and exit if asked
    usage_exit if params(:h)
    
    check_required_params
    
    info "====================="

    # Create and check lock file if enabled
    if self.class.enable_locking
      @lock = LockFile.new(lock_filename)
      @lock.quiet = true # Don't write errors to STDERR
      info "Use lock file: #{@lock.path}"
      if(@lock.lock)
        warn "Lock file '#{@lock.path}' already open in exclusive mode. Exit!"
        exit
      end
    end
    
    self.class.load_env

    begin
      # Log important info and call script job
      info "Log level = #{@logger.level}" if self.class.enable_logging
      info "Parameters: #{@params_values.inspect}"
      info "Starting script #{self.class.script_name}..."
      start = Time.now

      # Инкрементируем счетчик запусков этого скрипта
      inc_counter("#{self.class.script_name}_times")

      do!
      duration = Time.now - start
      info "Script #{self.class.script_name} finished!"
      info "Script job duration: #{duration}"
      info "Exit status: #{@exit_status}" if @exit_status

      # Инкрементируем время работы э
      inc_counter("#{self.class.script_name}_long", duration)

      # Log benchmarker info if it's not empty
      log_benchmarker_data
    rescue Exception => e
      # Print error info if it's not test env or exit
      if RailsStub.env != 'test' && e.class != SystemExit && e.class != Interrupt 
        msg = self.class.prepare_exception_message(e)
        puts "\n" + msg
        fatal msg
        notify_about_error(e)
      end

      # Инкрементируем счетчик ошибок этого скрипта
      inc_counter("#{self.class.script_name}_raised")
    ensure
      # Unlock lock file
      @lock.unlock if self.class.enable_locking && @lock
    end
  end

  # Print usage message and exit
  def usage_exit(message = nil)
    error "Exit with error message: #{message}" if message.present?
    Kernel.puts(self.class.usage(message))
    exit
  end

  # Dummy for do! method
  def do!; end

  # Override one or more parameters for testing purposes
  def override_parameters(args)
    if args.is_a?(Symbol)
      override_parameter(self.class.get_parameter(args))
    elsif args.is_a?(Hash)
      args.each{|key, value| override_parameter(self.class.get_parameter(key), value)}
    else
      raise "Parameter should be Symbol or Hash"
    end
  end

  # Return parameter value by key
  def params(key)
    param = self.class.get_parameter(key)

    # Use dafault key (if call by alias)
    key = param[:key]

    case param[:type]
    when :noarg
      return (@overrided_parameters.has_key?(key) && @overrided_parameters[key]) || !@params_values[key].nil?
    when :optional
      return @overrided_parameters[key] || @params_values[key] || param[:default]
    when :required
      value = @overrided_parameters[key] || @params_values[key] || param[:default]
      return value
    end
  end

  # Prepare filename of log file
  def lock_filename
    params(:L).blank? ? File.join(RailsStub.root, 'locks', "#{self.class.script_name}.lock") : params(:L)
  end

  # Prepare filename of log file
  def log_filename
    params(:l).blank? ? File.join(RailsStub.root, 'log', "#{self.class.script_name}#{log_filename_time_part}.log") : params(:l)
  end

  private

  # Current time logname part.
  def log_filename_time_part
    Time.now.strftime(self.class.date_log_postfix)
  end

  # Override value for one parameter
  def override_parameter(param, value = nil)
    value = case param[:type]
      when :noarg
        true
      when :optional
        value.to_s
      when :required
        value
    end
    @overrided_parameters[param[:key]] = value
  end

  # Print benchmarker statistic to log if its not empty
  def log_benchmarker_data
    benchmark_data = {} #benchmark_get_data
    return if benchmark_data.empty?
    info "Benchmarker data:"
    info benchmark_data.to_yaml
  end

  # Prepare string with exception details
  def self.prepare_exception_message(e)
<<-EXCEPTION
Exception happend
Type: #{e.class.inspect}
Error occurs: #{e.message}
Backtrace: #{e.backtrace.join("\n")}
EXCEPTION
  end

  def inc_counter(id, counter = 1)
    # stub    
  end
  
  def notify_about_error(ex)
    # stub
  end
  
end