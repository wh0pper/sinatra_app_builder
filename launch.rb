#!/usr/bin/ruby
require 'fileutils'

class Project
  def initialize(project_name, classes)
    @project_name = project_name
    @classes = classes
  end

  def create
    FileUtils.cd ".."
    puts FileUtils.pwd()
    FileUtils.mkdir(@project_name)
      FileUtils.cd "#{@project_name}"
      FileUtils.mkdir("lib")
      FileUtils.mkdir("views")
      FileUtils.mkdir("spec")
      FileUtils.mkdir("public")
      FileUtils.mkdir("config")
        FileUtils.cd "public"
        FileUtils.mkdir("css")
        FileUtils.touch("css/styles.css")
        FileUtils.mkdir("js")
        FileUtils.touch("js/scripts.js")
        FileUtils.mkdir("img")
      FileUtils.cd ".."
        File.open("Gemfile", 'w') { |file| file.write(
          "source 'https://rubygems.org'\n\ngem 'pg'\ngem 'sinatra'\ngem 'rspec'\ngem 'pry'\ngem 'sinatra-contrib', :require => 'sinatra/reloader'\ngem 'sinatra-activerecord'\ngem 'rake'")}
        system "bundle install"
        system "bundle update"

        File.open("app.rb", 'w') { |file| file.write(
          "require('sinatra')\nrequire('sinatra/reloader')\nrequire('sinatra/activerecord')\nalso_reload('lib/**/*.rb')\nrequire('pry')\nrequire('pg')\n")}

        File.open("spec/#{@project_name}_integration_spec.rb", 'w') {|file| file.write(
          "require 'spec_helper'\n\nCapybara.app = Sinatra::Application\nset(:show_exceptions, false)\n\ndescribe '', {:type => :feature} do\n  it '' do\n    visit '/'\n    fill_in('', :with => '')\n    click_button('')\n    expect(page).to have_content('')\n  end\nend"
          )}
        FileUtils.cd "views"
          FileUtils.touch("index.erb")
            File.open("layout.erb", 'w') {|file| file.write(
              "<!DOCTYPE html>\n<html>\n  <head>\n    <link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css'>\n    <link rel='stylesheet' href='<%= url('../css/styles.css')%>'>\n    <script type='text/javascript' src='../js/scripts.js'></script>\n    <script type='text/javascript' src='https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.js'></script>\n    <title>Insert Title</title>\n  </head>\n  <body> \n    <div class='container'>\n      <%= yield %>\n    </div>\n  </body> \n</html>")}

      FileUtils.cd ".."
      FileUtils.cd "config"
        File.open("database.yml", 'w') {|file| file.write(
          "development:\n  adapter: postgresql\n  database: #{@project_name}_development\n\ntest:\n  adapter: postgresql\n  database: #{@project_name}_test"
          )}
      FileUtils.cd ".."
        File.open("Rakefile", 'w') {|file| file.write("require 'sinatra/activerecord'\nrequire 'sinatra/activerecord/rake'\n\nnamespace(:db) do\n  task(:load_config)\nend"
          )}
        File.open("spec/spec_helper.rb", 'w') {|file| file.write("ENV['RACK_ENV'] = 'test'\nrequire 'rspec' \nrequire 'pry'\nrequire 'pg'\n")}

    @classes.each do |each_class|
      each_class = each_class.capitalize
      file_contents = "#!/usr/bin/env ruby\nclass #{each_class} < ActiveRecord::Base\nend"
      File.open("lib/#{each_class}.rb", 'w') { |file| file.write(file_contents) }
      File.open("spec/#{each_class}_spec.rb", 'w') { |file| file.write("require 'spec_helper'\n\ndescribe('#{each_class}'\) do\n  it(\"What you are testing\") do\n    expect().to(eq())\n  end\nend") }
      File.open('spec/spec_helper.rb', 'a') { |f|
  f.puts "require '#{each_class}'"}
      File.open("app.rb", 'a') { |file| file.puts("require('#{each_class}')\n")}
    end

    File.open("spec/spec_helper.rb", 'a') {|file| file.puts("\nRSpec.configure do |config|\n  config.after(:each) do\n")}

    @classes.each do |each_class|
      File.open("spec/spec_helper.rb", 'a') {|file| file.puts("    #{each_class.capitalize}.all().each() do |#{each_class.downcase}|\n      #{each_class.downcase}.destroy()\n    end\n  end\n")}
    end
    File.open("spec/spec_helper.rb", 'a') {|file| file.puts("end")}

    File.open("app.rb", 'a') { |file| file.puts(
      "\n\nget('/') do\n  erb:index\nend\n\npost('/') do\n  erb:index\nend")}

  end
end

puts "Enter project name: "
project_name = gets.chomp
puts "Enter class names for primary .rb file "
classes = gets.chomp
classes = classes.split(" ")
project = Project.new(project_name, classes)
project.create
