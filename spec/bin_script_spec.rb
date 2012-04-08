require File.dirname(__FILE__) + '/spec_helper'

describe BinScript do
  before :each do
    root = Pathname.new(File.dirname(__FILE__) + '/../').realpath.to_s
    Rails.stub!(:root).and_return(root)
  end
  
  class TestScript < BinScript
    noarg    :n, "Test parameter that can't have argument"
    optional :o, :description => "Test parameter that can have argument", :alias => :oo
    required :r, :description => "Test parameter that should have argument", :alias => [:rr, :rrr]
  end

  describe "class name detection" do
    before(:all) do
      @test_date = [
        {:filename => "/prj/bin/nagios/some.rb", :parts => ['nagios','some'], :class => "Nagios::SomeNagiosScript", :files => ["app/models/nagios_script.rb", "app/models/bin/nagios/some_nagios_script.rb"]},
        {:filename => "/prj/bin/another.rb", :parts => ['another'], :class => "AnotherScript", :files => ["app/models/bin/another_script.rb"]}
      ]
      @test_keys = [:parts, :class, :files]
    end
    it 'should detect class name and filenames from source script filename' do
      @test_date.each do |test|
        result = BinScript.parse_script_file_name(test[:filename])
        @test_keys.each { |key| result[key].should == test[key] }
      end
    end
  end

  describe "parameters" do
    it 'should accept string as description' do
      TestScript.get_parameter(:n)[:description].should == "Test parameter that can't have argument"
    end

    it 'should accept hash as second parameter' do
      TestScript.get_parameter(:o)[:description].should == "Test parameter that can have argument"
    end

    it "should accept parameters of all types" do
      {:n => :noarg, :o => :optional, :r => :required}.each do |key,type|
        TestScript.get_parameter(key)[:type].should == type
      end
    end

    describe "required parameters" do
      it "should return correct requred argument value" do
        @script.override_parameters(:r => 'value')
        @script.params(:r).should == 'value'
      end
    end

    describe "overrided parameters for testing" do
      it "should return false or true for noarg parameters even without value" do
        @script.params(:n).should be_false
        @script.override_parameters(:n)
        @script.params(:n).should be_true
      end

      describe "optional parameters" do
        it "should return nil if parameter not set or empty string if no argument defined" do
          @script.params(:o).should be_nil
          @script.override_parameters(:o)
          @script.params(:o).should == ''
        end

        it "should return value of argument" do
          @script.params(:o).should be_nil
          @script.override_parameters(:o => 'value')
          @script.params(:o).should == 'value'
        end
      end

      describe "aliases" do
        it 'should accept and handle one alias' do
          @script.override_parameters(:o => 'value')
          @script.params(:o).should == 'value'
          @script.params(:o).should == @script.params(:oo)
        end

        it 'should accept and handle some alias' do
          @script.override_parameters(:r => 'value')
          @script.params(:r).should == 'value'
          @script.params(:r).should == @script.params(:rr)
          @script.params(:rr).should == @script.params(:rrr)
        end

        it 'should override parameters by alias' do
          @script.override_parameters(:oo => 'value')
          @script.params(:o).should == 'value'
        end

        describe "default values" do
          class DevValTestScript < BinScript
            optional :o, :default => "def opt value"
            required :r, :default => "def req value"
          end
          it 'should return default value if value for optional argument was not defiend' do
            DevValTestScript.new.params(:o).should == 'def opt value'
            DevValTestScript.new.params(:r).should == 'def req value'
          end
        end
      end
    end
  end

  describe "usage" do
    it "should generate usage message" do
      USAGE = <<USAGE
Use: ./bin/test_script.rb [OPTIONS]

Availible options:

  -e v  Rails environment ID (default - development)
  -h    Print usage message
  -l v  Path to log file (default \#{Rails.root}/log/[script_name].log)
  -L v  Path to lock file (default \#{Rails.root}/locks/[script_name].lock)
  -n    Test parameter that can't have argument
  -o[v] Test parameter that can have argument
  -r v  Test parameter that should have argument

USAGE
      TestScript.usage.should == USAGE
    end
  end

  before(:each) do
    @script = TestScript.new
  end

  describe "locking" do
    it "should set default lock file" do
      @script.lock_filename.should == File.join(Rails.root, %w{locks test_script.lock})
    end

    it "should overwrite lock filename with option -L" do
      @script.override_parameters(:L => '/tmp/test_script.lock')
      @script.lock_filename.should == '/tmp/test_script.lock'
    end

    it "should create lock file while execute do! and delete it after even when exceptions occurs" do
      # Extend test script
      class TestScript
        attr_accessor :lock_file_has_been_created
        attr_accessor :raise_before_finish
        def do!
          self.lock_file_has_been_created = File.exist?(lock_filename)
          raise "Test exception" if self.raise_before_finish
        end
      end
      @script.raise_before_finish = false
      @script.lock_file_has_been_created.should_not be_true
      @script.run!
      @script.lock_file_has_been_created.should be_true
      File.exist?(@script.lock_filename).should be_false

      # And now test case when execptions occurs while script executed
      @script.lock_file_has_been_created = false
      @script.raise_before_finish = true
      @script.run!
      @script.lock_file_has_been_created.should be_true
      @script.raise_before_finish = true
      File.exist?(@script.lock_filename).should be_false
    end
  end

  describe "logging" do
    it "should set default log file correctly" do
      @script.log_filename.should == File.join(Rails.root, %w{log test_script.log})
    end

    it "should overwrite log filename with option -l" do
      @script.override_parameters(:l => '/tmp/test_script.log')
      @script.log_filename.should == '/tmp/test_script.log'
    end

    it "should create default logger" do
      default_log = File.join(Rails.root, %w{tmp test_script.log})
      File.delete(default_log) if File.exist?(default_log)
      @script.logger.should_not be_nil
    end
  end

end