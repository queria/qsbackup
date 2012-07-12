require 'pathname'

class BackupDir

  def initialize(dir_path)
    @_backup_dir = Pathname.new(dir_path)
    unless @_backup_dir.directory?
      raise "Backup directory #{dir_path} does not exist!"
    end
    @_stamp = Time.new.strftime('%Y%m%d-%H%M%S')
    @_stamp_dir = nil
  end

  def stamp_dir
    unless @_stamp_dir and @_stamp_dir.directory?
      @_stamp_dir = @_backup_dir + @_stamp
      @_stamp_dir.mkpath
      unless @_stamp_dir.directory?
        raise "Unable to write into backup dir (#{backup_dir})!"
      end
    end
    return @_stamp_dir
  end

end
