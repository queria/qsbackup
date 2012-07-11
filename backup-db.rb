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

def filter_databases(databases, skip_info_schema=true, skip_dbnames=[])
	databases.select do |dbname|
		(dbname != 'information_schema' or not skip_info_schema) \
		and (not skip_dbnames.include? dbname)
	end
end

def dump_db(dbcfg, dbname, backup_dir)
	db_path = backup_dir + (dbname + '.sql.bz2')
	`mysqldump --quick --disable-keys -u #{dbcfg['user']} -p#{dbcfg['pass']} #{dbname} | bzip2 -c > #{db_path.to_s}`
end

begin
  require_relative 'lib/commons.rb'
rescue NoMethodError
  require 'lib/commons'
end

args = Args.new(
  [:string, 'Path to configuration file', :config, :c],
  [:bool, 'Display this help information', :help, :h]
)
args.process(ARGV)

if args.has? :help
  puts args.to_s
  exit 0
end

config_path = './backup-db.cfg'
config_path = args.get(:config, config_path)
config = YAML::load_file(config_path)
config['skip_dbs'] ||= ''

db_config = {'user'=>config['user'], 'pass'=>config['pass']}
dbs = list_databases(db_config)
dbs = filter_databases(dbs, config['skip_info_schema'], config['skip_dbs'].split(':'))

if dbs.empty?
	puts 'No database to backup found!'
	exit 0
end

backup_dir = Pathname.new(config['backup_dir'])
unless backup_dir.directory?
	puts 'Backup directory does not exist!'
	exit 1
end

stamp = Time.new.strftime('%Y%m%d-%H%M%S')
backup_dir += stamp
backup_dir.mkpath
unless backup_dir.directory?
	puts "Unable to write into backup dir (#{backup_dir})!"
	exit 2
end

success = true
output = []
dbs.each do |db|
	dump_message = dump_db(db_config, db, backup_dir)
	if $?.exitstatus
		output << "Backup of #{db} created successfully"
	else
		success = false
		output << "Backup of #{db} failed!"
		output << dump_message
	end
end

unless success
	puts output.join "\n"
end

exit 0

