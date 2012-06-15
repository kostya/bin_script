Rails BinScript
===============

Easy writing and executing bins(executable scripts) in Rails Application (especially for crontab or god).
For my purposes much better than Rake, Thor and Rails Runner.

Features:

1. Each bin is a class
2. Easy writing tests
3. Bin use lock file and logger with formatter when executing
  
Rails 2.3 and 3 compatible

``` ruby
gem 'bin_script'
```

    rails generate bin:bin bla
    
    (for 2.3 copy generator into lib/generators and run: ./script/generate bin bla)

Call like:

    $ cd project && ./bin/bla.rb -e production --test -d "2012-04-07" -u "asdf"

Features by default:

    $ ./bin/bla.rb -h
    $ ./bin/bla.rb -e production 
    $ ./bin/bla.rb -e production -L ./locks/bla.lock
    $ ./bin/bla.rb -e production -l ./log/bla.log
    $ ./bin/bla.rb -e production --daemonize --pidfile ./tmp/bla.pid


Example Bin
-----------
app/models/bin/bla_script.rb

``` ruby
class BlaScript < BinScript
  optional :u, "Update string"
  required :d, :description => "Date in format YYYY-MM-DD or YYYY-MM", :default => "2012-04-01"
  noarg    :t, :decription => "Test run", :alias => 'test'
  
  self.description = "Super Bla script"
  
  def test?
    params(:t)
  end

  def do!
    if test?
      logger.info "update string #{params(:u)}"        
    else  
      logger.info "data #{params(:d)}"
    end
  end
end
```

### Options

``` ruby
class BlaScript < BinScript
  self.log_level = Logger::DEBUG
  self.enable_locking = false
  self.enable_logging = false
end
```

### Custom exception notifier (create initializer with:)

``` ruby
class BinScript
  def notify_about_error(exception)
      Mailter.some_notification(exception)...
  end
end
```

        