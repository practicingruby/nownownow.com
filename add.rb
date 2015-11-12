require_relative 'init.rb'
require_relative 'visit.rb'

# add a new URL: ruby add.rb something.net/now

short = ARGV[1]
raise 'bad URL' unless /\S+\.\S+/ === short

res = DB.exec_params("INSERT INTO now.urls (short) VALUES ($1) RETURNING *", [short])
puts res[0].inspect
id = res[0]['id']

visit

res = DB.exec_params("UPDATE now.urls
	SET tiny=SUBSTRING(short, 1, position('.' IN short) - 1)
	WHERE id=$1 RETURNING *", [id])
puts res[0].inspect
