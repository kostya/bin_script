Rails BinScript
===============

Easy writing and executing bins (espesually for crontab or god) in Rails project
For my purposes much better than Rake, Thor and Rails Runner

Features:

1. Each bin is a class
2. Easy writing tests
3. Bin use lock file and logger with formatter when executing
  
Rails 2.3 and 3 compatible

``` ruby
gem 'bin_script'
```

    rails g bin:bin bla
    (for 2.3 copy generator into lib/generators and run: ./script/generate bin bla)

Call like:

    $ cd project && ./bin/bla.rb -e production -a -b -c -d "asdf"

Examples (default features):

    $ ./bin/bla.rb -e production 
    $ ./bin/bla.rb -e production -L ./locks/bla.lock
    $ ./bin/bla.rb -e production -l ./log/bla.log
    $ ./bin/bla.rb -e production --daemonize --pidfile=./tmp/bla.pid



Example Bin
-----------
app/models/bin/stuff_script.rb

``` ruby
class StuffScript < BinScript
  optional :u, "Update string"
  required :d, "Date in format YYYY-MM-DD or YYYY-MM"
  noarg    :t, "Test run"
  
  def test?
    params(:t)
  end

  def do!
    if test?
      logger.info "update string #{params(:u)}"        
    else  
      logger.info "data #{Time.parse(params(:d))}"
    end
  end
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
  