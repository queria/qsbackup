class DBBackup

  def initialize(config, args)
    @_config = config
    @_args = args
    @_success = false
    @_output = []
  end

  def success?
    @_success
  end

  def output
    @_output.join("\n")
  end

  def do_backup
    dbs = get_databases
    if dbs
      stamp_dir = BackupDir.new(@_config['backup_dir']['db']).stamp_dir
      @_success = true
      dbs.each do |db_name|
          dump_db(db_name, stamp_dir)
      end
    end
    return @_success
  end

  def get_databases
    dbs = list_databases(@_config.for_db)
    dbs = filter_databases(dbs, @_config['skip_dbs'])

    if dbs.empty?
      @_success = false
      @_output << 'No database to backup found!'
      return nil
    end

    return dbs
  end

  def list_databases(dbcfg={'user'=>'','pass'=>''})
    matchreg = /Database: /
    output = `mysql -u #{dbcfg['user']} -p#{dbcfg['pass']} -e 'show databases\\G'`
    return nil if output.nil?
    output = output.split("\n") if output.is_a? String
    databases = []
    output.each do |line|
      if line =~ matchreg
        databases << line.sub(matchreg, '').strip
      end
    end
    return databases
  end

  def filter_databases(databases, skip_dbnames=[])
    databases.select do |dbname|
      not skip_dbnames.include? dbname
    end
  end

  def dump_db(dbname, backup_dir)
    db_path = backup_dir + (dbname + '.sql.bz2')
    dbcfg = @_config.for_db

    `mysqldump --quick --disable-keys -u #{dbcfg['user']} -p#{dbcfg['pass']} #{dbname} | bzip2 -c > #{db_path.to_s}`

    if $?.exitstatus
        @_output << "Backup of #{dbname} created successfully"
        return true
    end

    @_success = false
    @_output << "Backup of #{dbname} failed!"
    @_output << dump_message
    return false
  end

end
