=begin
	This library is meant to allow monitoring scripts to send notifications to
	and take commands from Microsoft Teams channels. This will allow for easy,
	organized control over these daemons.

	This code is kind of a fork from msteams-ruby-client

	Usage:
		require 'teams-lib.rb'
		hook_url = '[Webhook URL]'
		teams = Teams.new(hook_url)
		teams.post(
			bot:	'[Bot Name]',
			text:	'[Message]'
		)

		returns false if there is an error, else returns true
=end

#requirements
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

#teams class
class Teams
	def initialize(webhook_url = nil)
		@webhook_url = webhook_url
	end

	def post(options = {})
		uri = URI.parse(@webhook_url)
		http = Net::HTTP.new(uri.host, uri.port)

		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		req = Net::HTTP::Post.new(uri.request_uri)
		req['Content-Type'] = 'application/json'
		req.body = {
			title:	options[:bot],
			text:	format(options[:text])
		}.to_json

		res = http.request(req)

		#error handling
		if res.code != 200 || res.body != 1
			return false
		else
			return true
		end

		#DEBUG
#		puts "Response Code:\t"
#		puts res.code
#		puts "Response Body:\n"
#		puts res.body
	end

	def format(text)
		html = text.clone
		URI::DEFAULT_PARSER.extract(text, %w[http https]).uniq.each do |url|
			html.gsub!(url, %(<a href="#{url}">#{url}</a>))
		end

		html.gsub!("\n", "<br>\n")
		html
	end
end
