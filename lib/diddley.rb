require 'yaml'

class Diddley
  def initialize
    @config_file = 'config/botdiddley.yml'
    read_config
  end

  def read_config
    # load,
    begin
      config = YAML.load_file(@config_file)
    rescue Errno::ENOENT
      $stderr.print "oh my, couldn't open config file: #{@config_file}\n"
      exit
    end
    # check
    needed = %w[twitteruser twitterpass owner interval]
    needed.each do |wants|
      if not config[wants]
        puts "oh my, config is missing #{wants}."
        exit
      end
    end
    # & save.
    @twitteruser = config['twitteruser']
    @twitterpass = config['twitterpass']
    @owner       = config['owner']
    @interval    = config['interval']
  end

  def go!
    puts 'here we go!'
  end
end