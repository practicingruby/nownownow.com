require 'erb'
require 'pg'
require 'net/http'

DB = PG::Connection.new(port: 5433, hostaddr: '127.0.0.1', dbname: 'd50b', user: 'd50b')

def h(str)
	ERB::Util.html_escape(str)
end

def autolink(str)
	str.gsub(/(http\S*)/, '<a href="\1">\1</a>')
end

desc 'visit short URLs to get real/long URL'
task :visit do
	res = DB.exec("SELECT id, short FROM now.urls WHERE long IS NULL")
	res.each do |r|
		id = r['id']
		u = r['short']
		url = 'http://' + u
		res = Net::HTTP.get_response(URI(url))
		if res.code == '200'
			DB.exec_params("UPDATE now.urls SET long=$1, updated_at=NOW() WHERE id=$2", [url, id])
		elsif %w(301 302).include? res.code
			if res['location'].start_with? 'http'
				url = res['location'].gsub('blogspot.co.nz', 'blogspot.com')
			else
				url = 'http://' + URI(url).host + res['location']
			end
			DB.exec_params("UPDATE now.urls SET long=$1, updated_at=NOW() WHERE id=$2", [url, id])
		elsif res.code == '404'
			url = 'http://www.' + u
			res = Net::HTTP.get_response(URI(url))
			if res.code == '200'
				DB.exec_params("UPDATE now.urls SET long=$1, updated_at=NOW() WHERE id=$2", [url, id])
			else
				puts url + "\t" + res.inspect
			end
		else
			puts url + "\t" + res.inspect
		end
	end
end

desc 'make profile pages'
task :profiles do
	template = File.read('templates/profile.erb')
	@shuffle = File.read('templates/shuffle.js')
	# get everyone with profile info
	@profiles = DB.exec("SELECT s.person_id, n.tiny, p.name FROM peeps.stats s
		JOIN now.urls n ON s.person_id=n.person_id
		JOIN peeps.people p ON s.person_id=p.id
		WHERE s.statkey='now-title' ORDER BY s.person_id")
	@profiles.map{|r| r['person_id'].to_i}.each do |person_id|
		puts person_id
		# get person info
		res = DB.exec("SELECT p.name, p.city, p.state, c.name AS country
			FROM peeps.people p JOIN peeps.countries c ON p.country=c.code
			WHERE id=#{person_id}")
		@person = res[0]
		# get now.url
		res = DB.exec("SELECT tiny, short, long FROM now.urls WHERE person_id=#{person_id}")
		@now = res[0]
		# image either img src path or false
		@image = '/images/300/%s.jpg' % @now['tiny']
		@image = false unless File.exist?('site%s' % @image)
		# get other urls
		res = DB.exec("SELECT url FROM peeps.urls WHERE person_id=#{person_id}
			AND url NOT LIKE '%www.cdbaby.com%' ORDER BY main DESC NULLS LAST, id")
		@urls = res.map{|r| r['url']}
		# get profile answers
		res = DB.exec("SELECT statkey, statvalue FROM peeps.stats
			WHERE person_id=#{person_id} AND statkey LIKE 'now-%'")
		@profile = {}
		res.each do |r|
			# save in hash skipping the "now-" part of key: liner, red, thought, title, why
			@profile[r['statkey'][4..-1]] = r['statvalue']
		end
		# merge into template, saving as tiny
		File.open('site/p/' + @now['tiny'], 'w') do |f|
			f.puts ERB.new(template, nil, '-').result
		end
	end
end

desc 'write an updated index.html'
task :index do
	@urls = []
	res = DB.exec("SELECT tiny, short, long FROM now.urls
		WHERE tiny IS NOT NULL AND long IS NOT NULL ORDER BY short")
	res.each do |r|
		url = {long: r['long'], short: r['short'], profile: ''}
		profile_link = 'p/' + r['tiny']
		if File.exist?('site/' + profile_link)
			url[:profile] = ' (<a href="%s">+</a>)' % profile_link
		end
		@urls << url
	end
	@shuffle = File.read('templates/shuffle.js')
	File.open('site/index.html', 'w') do |f|
		f.puts ERB.new(File.read('templates/index.erb'), nil, '>').result
	end
end

desc 'add a new URL: rake add something.net/now'
task :add do
	short = ARGV[1]
	raise 'bad URL' unless /\S+\.\S+/ === short
	res = DB.exec_params("INSERT INTO now.urls (short) VALUES ($1) RETURNING *", [short])
	u = res[0]
	puts u.inspect
	Rake::Task['visit'].execute
	res = DB.exec("UPDATE now.urls
		SET tiny=SUBSTRING(short, 1, position('.' IN short) - 1)
		WHERE id=%d RETURNING *" % u['id'])
	puts res[0].inspect
end

