require 'yaml'
require 'rubygems'
require 'json'

class Diddley
  def initialize
    @last_seen_followers = nil
    @config_file = 'config/botdiddley.yml'
    read_config
    @auth = [@twitteruser, @twitterpass].join(":")
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
    report "bot diddley reporting for service at pid #{$$}."
    while true
      report "wha? checking #{@owner}'s followers."
      check_followers
      report "sleeping."
      sleep(@interval * 60)
    end
  end

  def report(msg)
    puts "#{Time.now} #{msg}"
  end

  # checks if there are new followers or if a followers stopped following,
  # formats and sends tweets to owner.
  def check_followers()
    fresh = fetch_followers
    unless @last_seen_followers.nil?
      new_followers = fresh - @last_seen_followers
      unfollowers   = @last_seen_followers - fresh
      report("new followers: "+new_followers.to_s) unless new_followers.empty?
      report("unfollowers: "+unfollowers.to_s) unless unfollowers.empty?
      msgs = []
      msgs += format_followers(new_followers)
      msgs += format_unfollowers(unfollowers)
      send_tweets(msgs)
    end
    @last_seen_followers = fresh
  end

  # returns list of followers' ids
  def fetch_followers()
    url = "http://twitter.com/statuses/followers.json?id=" + @owner
    cmd = "curl -u #{@auth} #{url}"
    j = %x[#{cmd}]  # TODO: how to capture error condition?
    #j = %x[cat tests/fixtures/followers.json] # local
    followers = JSON.parse(j)
    followers_ids = followers.map { |follower| follower['screen_name'] }
    # TODO: if followers.length > 100, fetch again.
    return followers_ids
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
      report 'send tweet: ' + msg
      url = "http://twitter.com/statuses/update.xml"
      cmd = "curl -u #{@auth} -d 'status=#{msg}' #{url}"
      r = %x[#{cmd}]
    end
  end
end
