#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'

API_ENDPOINT = "https://api.pinboard.in"
API_VERSION = "v1"

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

def pinboard_cmd(cmd, api_token)
   params = { 'auth_token' => api_token, 'format' => 'json'}
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
end
##########################################

api_token = load_api_token
if api_token != nil 
   res = pinboard_cmd("notes/list/", api_token)
   puts res.inspect
   json = JSON.parse(res.body)
   notes = json["notes"]
   notes.each do |note|
      id = note["id"]
      res = pinboard_cmd("notes/#{id}",api_token)
      puts res.body.inspect
      sleep 1
   end
end
