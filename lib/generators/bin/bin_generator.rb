# for Rails 3
if Rails::VERSION::MAJOR >= 3

  module Bin
    class BinGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("../templates", __FILE__)

      def add_files
        template "script.rb", "bin/#{file_path}"
        template "script_class.rb", "app/bins/#{file_path}_script.rb"
        template "spec.rb", "spec/bins/#{file_path}_script_spec.rb"
        chmod "bin/#{file_path}", 0755
      end
    end
  end

end

# for Rails 2.3
if Rails::VERSION::MAJOR == 2

  class BinGenerator < Rails::Generator::NamedBase
    def manifest
      record do |m|
        m.template "script.rb", "bin/#{file_path}", :chmod => 0755
        m.template "script_class.rb", "app/bins/#{file_path}_script.rb"
        m.directory "spec/bins"
        m.template "spec.rb", "spec/bins/#{file_path}_script_spec.rb"
      end
    end
  end

end