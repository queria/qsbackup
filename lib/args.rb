
class Args
  # Example usage:
  #
  # ... ARGV => ['-v', 'neco', '--debug']
  # args = Args.new(
  #   [:string, 'Be very verbose', :verbose, :v],
  #   [:bool, 'Print trace informations', :debug, :d],
  #   [:string, 'Run spec-tests', :test]
  # )
  # args.process(ARGV)
  #
  # args.has? :verbose => true
  # args[:verbose] => 'neco'
  # args.has? :d => true
  # args.has? :test => nil
  # args[:test] => nil
  #

  def initialize(*definition)
    @options = {}
    @options_aliases = {}
    @remaining_args = []

    _parse_definition(definition)
  end

  def remaining(index=nil)
    return @remaining_args[index] unless index.nil?
    return @remaining_args
  end

  def get(option_name,fallback=nil)
    option_name = has? option_name
    return @options[option_name][:value] if option_name
    return fallback
  end

  alias_method :[], :get

  def has?(option_name)
    option_name = option_name.to_s unless option_name.is_a? String
    if @options_aliases.has_key? option_name
      option_name = @options_aliases[option_name]
    end
    opt = @options[option_name]
    return option_name if opt and opt[:present]
    return nil
  end

  def process(args)
    awaiting_opt = nil
    args.each do |arg|
      unless awaiting_opt.nil?
        @options[ awaiting_opt ][:value] = arg
        awaiting_opt = nil
        next
      end

      name = _arg_to_opt_name(arg)
      awaiting_opt = _process_option(name, arg)
    end
  end

  def to_s
    out = ["Available arguments:"]
    @options.each_key do |opt_name|
      out_opt = " --#{opt_name}"

      opt = @options[opt_name]
      opt[:aliases].each do |opt_alias|
        out_opt += " -#{opt_alias}"
      end

      if opt[:type] == :string
        out_opt += " <value>"
      end

      out_opt += "\t" + opt[:description]

      out << out_opt
    end
    return out.join("\n")
  end

  private
  def _process_option(name, arg)
    if name and @options.has_key? name
      @options[name][:present] = true
      if @options[name][:type] == :bool
        @options[name][:value] = true
      elsif @options[name][:type] == :string
        return name # name of option for which we also need a value
      end
    else
      @remaining_args << arg
    end
    return nil
  end

  private
  def _arg_to_opt_name(arg)
    if arg.start_with? '--'
      return arg[2..-1]
    elsif arg.start_with? '-'
      return @options_aliases[ arg[1..-1] ]
    end
    return nil
  end

  private
  def _parse_definition(definition)
    definition.each do |opt|
      _parse_opt(opt)
    end
  end

  private
  def _parse_opt(option)
      type = option.shift
      desc = option.shift
      name = option.shift.to_s

      @options[ name ] = { :description => desc, :type => type, :present => false, :value => nil, :aliases => [] }

      option.each { |opt_alias|
        @options_aliases[ opt_alias.to_s ] = name
        @options[name][:aliases] << opt_alias.to_s
      }
  end
end

