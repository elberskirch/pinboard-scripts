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

   def self.request(cmd, api_token, user_params = nil, no_json = false)

      if no_json
         params = { 'auth_token' => api_token }
      else 
         params = { 'auth_token' => api_token, 'format' => 'json'}
      end

      if user_params != nil
         params = params.merge(user_params)
      end
      #puts cmd
      path = [API_ENDPOINT, API_VERSION, cmd].join("/")
      puts "Performing REST call: #{path}"
      req_url = [path,URI.encode_www_form(params)].join("?")
      uri = URI.parse(req_url)
      puts uri.inspect
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
      engine.render(Object.new, :data => data)
   end

   def self.haml_template
      template = <<-END.gsub(/^ {9}/,'')
         %html
            %body 
               %h2= data.title
               %ul  
                  - data.bookmarks.each do |bm|
                     %li 
                        =bm['time']
                        %a{:href=> bm['href']} 
                           =bm['description']
            - if data.random != nil
               %h2= "random link"
               %ul
                  %li
                     =data.random['time']
                     %a{:href => data.random['href']}
                        =data.random['description']
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

   def self.load_mailer_config() 
      mailer_file = File.join(ENV["HOME"],".mailer.json")
      mailer_config = nil
      if File.exists?(mailer_file)
         File.open(mailer_file) do |file|
            raw_config = file.read
            mailer_config = JSON.parse(raw_config, :symbolize_names => true)
         end
      else
         puts "PLEASE create a .mailer.json file in your HOME directory"
         exit
      end 
      mailer_config[:smtp]
   end
      
   def self.sendmail(to, subject, body, config)
      Pony.mail({
               :to => to,
               :subject => subject,
               :html_body => body,
               :via => :smtp,
               :via_options => config
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
      puts "fetch recent posts"
      posts = OpenStruct.new
      res = PinboardHelper.request("posts/recent/",api_token, "count" => count)

      #puts res.inspect
      response_data = JSON.parse(res.body)
      posts.user = response_data["user"]      
      posts.bookmarks = response_data["posts"]   
      posts.date = response_data["date"] 
      posts 
   end

   def self.random_post(api_token)
      puts "fetch random post"
      res = PinboardHelper.request("posts/dates/",api_token)
      response_data = JSON.parse(res.body)
      #puts response_data.inspect
      dates = response_data["dates"]
      date = dates.keys.sample # get a random date where at least one post was made
      #puts date
      res = PinboardHelper.request("posts/get/",api_token, :dt => date)
      response_data = JSON.parse(res.body)
      post = response_data["posts"].sample
      #puts post.inspect
      post
   end

   def self.run(args)
      api_token = PinboardHelper.load_api_token
      options = parse(ARGV)
      if api_token != nil
         posts = recent_posts(api_token, options.max)
         if options.html 
            posts.title = "Bookmarks for #{posts.date}"
            posts.random = random_post(api_token)
            table = PinboardDigest.html(posts)
         else 
            table = PinboardDigest.text(posts)
            table = table.to_s
         end
         puts table

         if options.receiver != nil
            config = load_mailer_config # prepare mailer setup
            sendmail(options.receiver, "PinboardDigest #{Time.now}",table, config)
         end
      end
   end
end

PinboardDigest.run(ARGV)
