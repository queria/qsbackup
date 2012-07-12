#!/usr/bin/env ruby
begin
  require_relative 'lib/commons.rb'
rescue NoMethodError
  require 'lib/commons'
end

default_config = './backup-db.cfg'

args = Args.new(
  [:string, 'Path to configuration file', :config, :c],
  [:bool, 'Always display output (default is only when error occured)', :verbose, :v],
  [:bool, 'Display this help information', :help, :h]
)
args.process(ARGV)

if args.has? :help
  puts "DBBackup script"
  puts ""
  puts " Creates dump of all databases (in mysql) and places them in backup_dir/timestamp/db_name.sql.bz2"
  puts " Connection, excludes and backup_dir etc can be customized in config file."
  puts " Default config file is: #{default_config}"
  puts ""
  puts args.to_s
  puts ""
  puts "Created by Queria Sa-Tas <public@sa-tas.net>"
  puts "For more info visit https://github.com/queria/qsbackup/"
  exit 0
end

config = ConfigFile.new(
  args.get(:config, default_config),
  'skip_dbs' => [],
)

backup = DBBackup.new(config, args)
backup.do_backup

if args.has? :verbose or not backup.success?
  puts backup.output
end

exit backup.success? ? 0 : 1

