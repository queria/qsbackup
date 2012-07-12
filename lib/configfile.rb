require 'yaml'

class ConfigFile

  def initialize(config_file, defaults)
    @_file = config_file
    @_config = YAML::load_file(config_file)
    defaults.each_key do |opt|
      @_config[opt] ||= defaults[opt]
    end
  end

  def [](key)
    unless @_config.has_key? key
      raise "Option #{key} no present in config file #{@_file}"
    end
    return @_config[key]
  end

  def for_db
    return {'user'=>self['db']['user'], 'pass'=>self['db']['pass']}
  end

end
