
def require_r(file)
  begin
    require_relative "#{file}.rb"
  rescue NoMethodError
    require file
  end
end

require_r 'args'

