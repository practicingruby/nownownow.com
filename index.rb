require_relative 'init.rb'

# write an updated index.html

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
