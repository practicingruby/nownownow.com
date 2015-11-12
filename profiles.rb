require_relative 'init.rb'
# make profile pages

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

