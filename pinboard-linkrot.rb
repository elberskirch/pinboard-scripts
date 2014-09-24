#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'time'

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
      JSON.parse(res.body)
   end

   def self.truncate(string, max)
      string.length > max ? "#{string[0...max]}..." : string
   end
end

############################################
class LinkRot 
   BOOKMARKS_FILE = "bookmarks.json"
   def initialize()
   end

   def load()
      file = File.open(BOOKMARKS_FILE, "r")
      data = file.read
      file.close
      JSON.parse(data)
   end

   def store(bookmarks)
      File.open(BOOKMARKS_FILE, "w") do |file|
         file.write bookmarks.to_json
      end
   end

   def run(args)
      api_token = PinboardHelper.load_api_token
      if api_token.nil?
         puts "ERROR: couldn't load api_token"
         exit(-1)
      end

      last_update = PinboardHelper.request("posts/update",api_token)['update_time']
      puts Time.parse(last_update)

      bookmarks = load
      bookmarks.each do |bm|
         puts "#{bm["hash"]}, #{Time.parse(bm["time"])}, #{bm["href"]}"
      end
   end
end

linkrot = LinkRot.new
linkrot.run(ARGV)
