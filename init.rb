require 'erb'
require 'pg'

DB = PG::Connection.new(port: 5433, hostaddr: '127.0.0.1', dbname: 'd50b', user: 'd50b')

def h(str)
	ERB::Util.html_escape(str)
end

def autolink(str)
	str.gsub(/(http\S*)/, '<a href="\1">\1</a>')
end

