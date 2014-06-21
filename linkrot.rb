#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'time'

BOOKMARKS_FILE = "bookmarks.json"

def load_api_token
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

class PinboardConnection
   API_ENDPOINT = "https://api.pinboard.in"
   API_VERSION = "/v1/"

   def initialize(api_token, endpoint = API_ENDPOINT, version = API_VERSION)
      @api_token = api_token
      @api_version = version
      @api_uri = URI.parse(endpoint)
   end
   
   def get(url)
      format = "format=json"
      http = Net::HTTP.new(@api_uri.host, @api_uri.port)
      http.use_ssl = true
      
      req_url = @api_version + url + "?auth_token=" + @api_token + "&" + format
       
      puts req_url
      req = Net::HTTP::Get.new(req_url)
      res = http.request(req)
      puts res.header.inspect
      puts res.body.inspect
      res.body
   end 

   def posts
      recent = get("posts/all")
      recent_posts = JSON.parse(recent)
   end
end

############################################
class Linkrot 
end

def run()
   time_diff = 301
   if File.exists? BOOKMARKS_FILE 
      time_diff = Time.now.tv_sec - File.mtime(BOOKMARKS_FILE).tv_sec
      puts "Difference in seconds: #{time_diff}"
   end

   # check if bookmarks file is older than 5 minutes, to limit api requests
   if time_diff > 300 
      api_token = load_api_token
      #puts api_token
      if api_token != nil 
         pinboard = PinboardConnection.new(api_token)
         posts = pinboard.posts
         puts "------------------------------------------------------------------------"
         puts "Received all bookmarks"
         puts "------------------------------------------------------------------------"
         File.open(BOOKMARKS_FILE, "w") do |file|
            file.write posts.to_json
            file.flush
         end
      end
   end

   bookmarks = JSON.parse(File.read(BOOKMARKS_FILE))
   bookmarks.each do |bm|
      puts "#{bm["hash"]}, #{bm["time"]}, #{bm["href"]}"
   end
end

run
