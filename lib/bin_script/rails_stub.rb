begin
  require 'rails' unless defined?(Rails)
rescue LoadError => e
end

module RailsStub

  def self.env
    defined?(Rails) ? Rails.env : ENV['RAILS_ENV']
  end

  def self.logger
    defined?(Rails) ? Rails.logger : nil
  end

  def self.root
    path = defined?(Rails) ? Rails.root : nil
    path ||= defined?(APP_ROOT) ? APP_ROOT : '.'
    Pathname.new(path).realpath.to_s
  end

end