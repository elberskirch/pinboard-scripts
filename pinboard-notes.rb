#!/usr/bin/env ruby
# Copyright (c) 2014 Dominik Elberskirch <dominik.elberskirch@gmail.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'net/http'
require 'uri'
require 'json'
require 'time'
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
##########################################

api_token = load_api_token
if api_token != nil 
   res = PinboardHelper.request("notes/list/", api_token)
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
