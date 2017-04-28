#!/usr/bin/env ruby

require 'net/http'
require 'nokogiri'
require 'cgi'

$baseurl = "http://art.by.virmir.com"

if $0==__FILE__
	puts "This file is a library file. It is not supposed to do anything when executed."
end
