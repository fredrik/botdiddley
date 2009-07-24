require 'pp'
require 'yaml'
require 'rubygems'
require 'json'

config = YAML.load_file('config.yml')
# TODO: catch Errno::ENOENT: No such file or directory
unless config['twitteruser'] and config['twitterpass'] and config['owner']       and config['interval']
  puts "ERROR: config incomplete."
  exit
end

auth = "#{config['twitteruser']}:#{config['twitterpass']}"
url = "http://twitter.com/statuses/followers.json?id=#{config['owner']}"
cmd = "curl -u #{auth} #{url}"

j = %x[#{cmd}]  # capture error how?
list = JSON.parse(j)

puts "some #{list.length} followers."

followers = list.map { |follower| follower['id'] }.sort
pp followers
