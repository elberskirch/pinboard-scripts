#!/usr/bin/env ruby
require 'net/http'
require 'uri'

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

api_endpoint = "https://api.pinboard.in"
api_version = "/v1/"
api_token = load_api_token

if api_token != nil 
   notes = "notes/list/"
   format = "format=json"
   uri = URI.parse(api_endpoint)
   http = Net::HTTP.new(uri.host, uri.port)
   http.use_ssl = true

   req_url = api_version + notes + "?auth_token=" + api_token + "&" + format
   puts req_url
   req = Net::HTTP::Get.new(req_url)
   res = http.request(req)

   puts res.inspect
   puts res.header.inspect
   puts res.body.inspect
end
