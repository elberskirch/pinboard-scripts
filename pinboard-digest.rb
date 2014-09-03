#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'time'
require 'terminal-table'

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
      puts cmd
      path = [API_ENDPOINT, API_VERSION, cmd].join("/")
      puts "path #{path}"
      req_url = [path,URI.encode_www_form(params)].join("?")
      uri = URI.parse(req_url)
      puts uri.inspect
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Get.new(req_url)
      res = http.request(req)
      puts res.inspect
      res
   end

   def self.truncate(string, max)
      string.length > max ? "#{string[0...max]}..." : string
   end
end

# get n last links, or last 7/14days, run it daily, if no links
# linkstats + random link

api_token = PinboardHelper.load_api_token
if api_token != nil
   res = PinboardHelper.request("posts/recent/",api_token)
   response_data = JSON.parse(res.body)

   bookmarks = response_data["posts"]
   #puts bookmarks.inspect
   rows = bookmarks.map {|bm| 
      [ PinboardHelper.truncate(bm["href"],40), 
        PinboardHelper.truncate(bm["description"],40), 
        bm["time"] ]
   }
   title = sprintf("user %s\ndate %s", response_data["user"],response_data["date"])
   table = Terminal::Table.new :title => title, :rows => rows, :width => 25

   puts table

=begin
   res = PinboardHelper.request("posts/dates/",api_token)
   date_stats = JSON.parse(res.body)
   date_stats.each do |date|
      puts date.inspect
   end
=end

end
