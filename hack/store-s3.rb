#!/usr/bin/env ruby
require 'rubygems'
require 'aws/s3'

class Hack
  def initialize
    @last_seen_followers = nil
    @followers_file = 'last_seen'
    @config_file = '../config/botdiddley.yml'
    read_config()
    @auth = [@twitteruser, @twitterpass].join
    connect_s3()
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
    needed = %w[twitteruser twitterpass owner interval AMAZON_ACCESS_KEY_ID AMAZON_SECRET_ACCESS_KEY AWS_BUCKET]
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
    @aws_key_id  = config['AMAZON_ACCESS_KEY_ID']
    @aws_key     = config['AMAZON_SECRET_ACCESS_KEY']
    @aws_bucket  = config['AWS_BUCKET']
  end
  def connect_s3
    AWS::S3::Base.establish_connection!(
      :access_key_id     => @aws_key_id,
      :secret_access_key => @aws_key
    )
  end

  def store(contents)
    AWS::S3::S3Object.store(@followers_file, contents, @aws_bucket)
    # TOOD: check response status - AWS::S3::Service.response
  end
  def fetch
    object = AWS::S3::S3Object.find(@followers_file, @aws_bucket)
    contents = object.value(:reload)
    # TOOD: check response status - AWS::S3::Service.response    
    return contents
  end
end

hack = Hack.new

contents = "hey ho?"
hack.store(contents)

hey = hack.fetch()
if hey != contents
  # fail!
  puts 'hey now, got something other than what I expected.'
end
puts hey
