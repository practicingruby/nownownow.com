#!/usr/bin/env ruby
#exit unless 'sivers.org' == %x{hostname}.strip
require 'pstore'
require 'pg'
require 'nownownow-config.rb'
require 'twitter'

DB = PG::Connection.new(dbname: 'd50b', user: 'd50b')

logfile = '/var/www/tiny/nowprofiles.pstore'
ps = PStore.new(logfile)

unless File.exist?(logfile)
	ps.transaction do
		ps[:log] = []
	end
end

def get_url
	res = DB.exec("SELECT p.id, n.tiny, p.name,
		regexp_replace(u.url, 'http.*twitter.com/', '') AS twitter FROM peeps.stats s
		JOIN now.urls n ON s.person_id=n.person_id
		JOIN peeps.people p ON s.person_id=p.id
		LEFT JOIN peeps.urls u ON (s.person_id=u.person_id AND u.url LIKE '%twitter.com/%')
		WHERE s.statkey='now-title' ORDER BY RANDOM() LIMIT 1")
	[res[0]['id'].to_i, res[0]['tiny'], res[0]['name'], res[0]['twitter']]
end

ps.transaction do
	begin
		id, tiny, name, twitter = get_url
	end while (ps[:log].map {|x| x[:id]}.include? id)
	tw = Twitter::REST::Client.new do |config|
		config.consumer_key = TWITTER_CONSUMER_KEY
		config.consumer_secret = TWITTER_CONSUMER_SECRET
		config.access_token = TWITTER_ACCESS_TOKEN
		config.access_token_secret = TWITTER_ACCESS_SECRET
	end
	tweet = '%s profile: http://nownownow.com/p/%s' % [name, tiny]
	if String(twitter).size > 0
		tweet << ' @%s' % twitter
	end
	tw.update tweet
	ps[:log] << {id: id, profile: tiny, when: Time.now()}
end

