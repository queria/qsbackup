#!/usr/bin/env ruby
require 'yaml'
require 'pathname'
require 'fileutils'

def list_databases(dbcfg={'user'=>'','pass'=>''})
	matchreg = /Database: /
	output = `mysql -u #{dbcfg['user']} -p#{dbcfg['pass']} -e 'show databases\\G'`
	return nil if output.nil?
	databases = []
	output.each do |line|
		if line =~ matchreg
			databases << line.sub(matchreg, '').strip
		end
	end
	return databases
end

def filter_databases(databases, skip_info_schema=true, skip_dbnames='')
	databases
end

def dump_db(dbcfg, dbname, backup_dir)
	db_path = backup_dir + (dbname + '.sql')
	puts "storing #{db_path}"
	`mysqldump --quick --disable-keys -u #{dbcfg['user']} -p#{dbcfg['pass']} #{dbname} > #{db_path.to_s}`
end

config_path = './backup-db.cfg'
config_path = ARGV[0] unless ARGV[0].nil?
config = YAML::load_file(config_path)

backup_dir = Pathname.new(config['backup_dir'])
unless backup_dir.directory?
	# or backup_dir.mkpath
	# -- dont create it to save troubles with typos ;)
	# -- let the user handle corner cases
	puts 'Backup directory does not exist!'
	exit 1
end

db_config = {'user'=>config['user'], 'pass'=>config['pass']}
dbs = list_databases(db_config)
dbs = filter_databases(dbs, config['skip_info_schema'], config['skip_dbs'])

dbs.each do |db|
	dump_db(db_config, db, backup_dir)
end

puts 'done'

