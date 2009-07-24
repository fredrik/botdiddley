#!/usr/bin/env ruby
# bot diddley, a twitter and blues bot that keeps track of your followers.

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'diddley'

diddley = Diddley.new
diddley.go!
