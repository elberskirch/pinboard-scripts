#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'time'
require 'terminal-table'
require 'haml'
require 'pony'
require 'ostruct'
require 'optparse'

module PinboardHelper
   API_ENDPOINT = "https://api.pinboard.in"
   API_VERSION = "v1"

   def self.load_api_token
      token_file = File.join(ENV["HOME"],".pinboard_token")
      token = nil
      if File.exists?(token_file)
         File.open(token_file) do |file|
            token = file.read.chomp
         end
      else
         puts "PLEASE create a .pinboard_token file in your HOME directory"
      end 
      token
   end

   def self.request(cmd, api_token, user_params = nil)

      params = { 'auth_token' => api_token, 'format' => 'json'}
      if user_params != nil
         params = user_params.merge(params)
      end
      #puts cmd
      path = [API_ENDPOINT, API_VERSION, cmd].join("/")
      puts "Performing REST call: #{path}"
      req_url = [path,URI.encode_www_form(params)].join("?")
      uri = URI.parse(req_url)
      #puts uri.inspect
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Get.new(req_url)
      begin 
         res = http.request(req)
      rescue SocketError => se
         puts "Caught a SocketError #{se}"
         puts "Seems like you're not connected to a network"
         exit 
      end
      #puts res.inspect
      res
   end

   def self.truncate(string, max)
      string.length > max ? "#{string[0...max]}..." : string
   end
end

module PinboardDigest
   def self.html(data)
      template = haml_template
      #puts template
      engine = Haml::Engine.new template
      engine.render(Object.new, :bookmarks => data.bookmarks)
   end

   def self.haml_template
      template = <<-END.gsub(/^ {9}/,'')
         %html
            %body 
               %ul  
                  - bookmarks.each do |bm|
                     %li 
                        %a{:href=> bm['href']} 
                           =bm['description']
      END
   end

   def self.text(data)
      rows = data.bookmarks.map {|bm| 
         [ PinboardHelper.truncate(bm["href"],40), 
         PinboardHelper.truncate(bm["description"],40), 
         bm["time"] ]
      }
      title = sprintf("user %s\ndate %s", data.user, data.date)
      table = Terminal::Table.new :title => title, :rows => rows, :width => 25
   end

   def self.mailerconfig() 
      mailerconfig = JSON.parse(File.read("mailer.json"), :symbolize_names => true)
      @@mailer_options = mailerconfig[:smtp]
      #puts @@mailer_options.inspect
   end
      
   def self.sendmail(to, subject, body)
      Pony.mail({
               :to => "dominik.elberskirch@gmail.com",
               :subject => subject,
               :html_body => body,
               :via => :smtp,
               :via_options => @@mailer_options
      })
   end

   def self.parse(args)
      #puts args.inspect
      options = OpenStruct.new
      options.html = false

      opt_parser = OptionParser.new do |opts|
         opts.banner = "Usage: pinboard-digest.rb -x|--html --receiver EMAIL --max COUNT"
         opts.on("-r", "--receiver EMAIL", "EMAIL receiver of the PinboardDigest") do |r|
            options.receiver = r 
         end

         opts.on("--max COUNT", Integer, "maximum COUNT of links per mail") do |c|
            if( c < 101 && c > 0 )
               options.max = c
            end
         end

         opts.on("-x", "--html", "use html format") do
            options.html = true
         end
      end
      opt_parser.parse!(args)
      
      if options.max == nil
         puts opt_parser
         exit
      end
      options
   end

   def self.recent_posts(api_token, count)
      posts = OpenStruct.new
      res = PinboardHelper.request("posts/recent/",api_token, "count" => count)

      #puts res.inspect
      response_data = JSON.parse(res.body)
      posts.user = response_data["user"]      
      posts.bookmarks = response_data["posts"]   
      posts.date = response_data["date"] 
      posts 
   end

   def self.random_post()
   end

   def self.run(args)
      api_token = PinboardHelper.load_api_token
      options = parse(ARGV)
      if api_token != nil
         posts = recent_posts(api_token, options.max)
         
         if options.html 
            table = PinboardDigest.html(posts)
         else 
            table = PinboardDigest.text(posts)
            table = table.to_s
         end
         puts table

         if options.receiver != ""
            mailerconfig # prepare mailer setup
            sendmail(options.receiver, "PinboardDigest #{Time.now}",table)
         end
      end
   end
end

PinboardDigest.run(ARGV)
