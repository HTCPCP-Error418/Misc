require 'rubygems'
require 'sinatra'					#gem install sinatra
require 'json'

post '/' do
	body = JSON.parse request.body.read
	puts body				#PARSE JSON TO GET COMMANDS HERE
end

#ACTIONS TO TAKE BASED ON JSON
