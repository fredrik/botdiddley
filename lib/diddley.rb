require 'rubygems'
require 'aws/s3'
require 'json'
require 'yaml'

class Diddley
  def initialize
    @config_file = 'config/botdiddley.yml'
    read_config()
    check_s3()
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
    needed = %w[twitteruser twitterpass owner interval followers_file aws_key_id aws_key aws_bucket]
    needed.each do |wants|
      if not config[wants]
        puts "oh my, config is missing #{wants}."
        exit
      end
    end
    # & save.
    @twitter_auth = [config['twitteruser'], config['twitterpass']].join(":")
    @owner       = config['owner']
    @interval    = config['interval']
    @aws_key_id  = config['aws_key_id']
    @aws_key     = config['aws_key']
    @aws_bucket  = config['aws_bucket']
    @followers_file = config['followers_file']
  end

  def check_s3
    AWS::S3::Base.establish_connection!(
      :access_key_id     => @aws_key_id,
      :secret_access_key => @aws_key
    )

    # check credentials
    begin
      AWS::S3::Service.buckets
    rescue AWS::S3::S3Exception => error
      # now, the following two exceptions are also available, but.. ARGH!
      # AWS::S3::InvalidAccessKeyId
      # AWS::S3::SignatureDoesNotMatch
      puts 'error: improper S3 credentials.'
      puts error
      exit()
    end

    # check existance of bucket.
    # create bucket if it doesn't exist.
    begin
      b = AWS::S3::Bucket.find(@aws_bucket)
    rescue AWS::S3::NoSuchBucket
      puts "bucket #{@aws_bucket} not found; creating."
      AWS::S3::Bucket.create(@aws_bucket)
    end
  end

  def go!
    report "bot diddley reporting for service at pid #{$$}."
    while true
      report "wha? checking #{@owner}'s followers."
      check_followers
      report "sleeping for #{@interval} minutes."
      sleep(@interval * 60)
    end
  end

  def report(msg)
    puts "#{Time.now} #{msg}"
  end

  # check if there are new followers or if someone unfollowed.
  # send tweet to owner.
  def check_followers()
    fresh = fetch_followers()
    last_seen = fetch_last_seen_followers()
    unless last_seen.nil?
      new_followers = fresh - last_seen
      unfollowers   = last_seen - fresh
      msgs = []
      unless  new_followers.empty?
        report("new followers: " + new_followers.to_s)
        msgs += format_followers(new_followers)
      end
      unless unfollowers.empty?
        report("unfollowers: "+unfollowers.to_s)
        msgs += format_unfollowers(unfollowers)
      end
      if msgs.empty?
        puts 'nothing to report.'
      else
        send_tweets(msgs)
      end
    end
    # store list of followers on S3.
    store_followers(fresh)
  end

  # returns list of followers' ids
  def fetch_followers()
    url = "http://twitter.com/statuses/followers.json?id=" + @owner
    cmd = "curl -u #{@twitter_auth} #{url}"
    j = %x[#{cmd}]  # TODO: how to capture error condition?
    #j = %x[cat tests/fixtures/followers.json] # local
    followers = JSON.parse(j)
    follower_names = followers.map { |follower| follower['screen_name'] }
    # TODO: if followers.length > 100, fetch again.
    return follower_names
  end

  # TODO: squeeze many followers into one msg.
  def format_followers(list)
    return [] if list.empty?
    return list.map {|follower| "@#{@owner}: @#{follower} is now following you."}
  end
  def format_unfollowers(list)
    return [] if list.empty?
    return list.map {|unfollower| "@#{@owner}: @#{unfollower} is no longer following you."}
  end

  def send_tweets(msgs)
    msgs.each do |msg|
      report 'sending tweet: ' + msg
      url = "http://twitter.com/statuses/update.xml"
      cmd = "curl -u #{@twitter_auth} -d 'status=#{msg}' #{url}"
      r = %x[#{cmd}]
    end
  end

  # store list of followers on S3.
  def store_followers(ary)
    puts 'storing list of followers on s3.'
    contents = ary.to_json
    AWS::S3::S3Object.store(@followers_file, contents, @aws_bucket)
    unless AWS::S3::Service.response.success?
      puts "failed to store #{@followers_file}."
    end
  end

  # fetch list of followers from S3.
  # returns nil if file does not exist.
  def fetch_last_seen_followers
    puts 'fetching list of followers from s3.'
    begin
      # fetch json from S3.
      object = AWS::S3::S3Object.find(@followers_file, @aws_bucket)
    rescue AWS::S3::NoSuchKey
      puts 'there is no followers file on S3.'
      return nil
    end

    begin
      # parse json.
      followers = JSON.parse(object.value)
    rescue JSON::ParserError
      puts "json parse error. clearing #{@followers_file}."
      AWS::S3::S3Object.delete(@followers_file, @aws_bucket)
      unless AWS::S3::Service.response.success?
        puts "hey, could not delete #{@followers_file}!"
      end
    end

    return followers
  end

end
