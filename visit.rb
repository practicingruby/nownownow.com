require_relative 'init.rb'
require 'net/http'

# visit short URLs to get long
# called from add.rb but can also be run separately

def visit
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

if __FILE__ == $0
	visit
end

