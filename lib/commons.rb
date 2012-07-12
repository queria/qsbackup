
def require_r(file)
  begin
    require_relative "#{file}.rb"
  rescue NoMethodError
    require file
  end
end

require_r 'args'
require_r 'configfile'
require_r 'backupdir'
require_r 'dbbackup'

