#!/usr/bin/env ruby

load 'startup.rb' # init libs and stuff

usgstr = "USAGE: ruby #{__FILE__} <TAGS_AS_STRING> [<page>|<start>-<end>|all] [LOW|hi]"
tags,pagenum,mode = ARGV
(tags&&pagenum&&mode)||abort(usgstr)
ARGV.clear

if pagenum.match(/^\d+$/)
	pagenum_mode = :single
elsif pagenum.match(/^\d+-\d+$/)
	pagenum_mode = :range
	pagenum_start = pagenum.match(/^(\d+)/)[1].to_s.to_i
	pagenum_end = pagenum.match(/(\d+)$/)[1].to_s.to_i
else
	pagenum_mode = :all
end


tags_esc = CGI::escape tags

mode_uri = (mode.downcase=="hi" ? "full" : "standard")
picdir = "pics/search/#{tags_esc}/#{mode_uri}/"

picdir.split("/").inject do |cur,sub|
	cur.is_a?(Array)||cur=[cur]
	Dir.mkdir(cur.join("/")) rescue nil
	cur << sub
end

Dir.mkdir(picdir) rescue nil

case pagenum_mode
when :single
	page = Nokogiri::HTML Net::HTTP.get(URI $baseurl+"?search=#{tags_esc}&page=#{pagenum}")
	imgs = page.css('div.thumb')
	imgs.empty?&&abort("Page number to large(or nothing found).")
	imgs = imgs.map{|i|"/i/#{mode_uri}/#{i.children.first.children.first.attributes["href"].value.split("/").last}.png"}
	imgs.each_with_index do |img,ind|
		(puts("(#{ind+1}/#{imgs.length}) Skipping #{img} (already exists)");next) if File.exists?(picdir+img.split("/").last)
		puts "(#{ind+1}/#{imgs.length}) Downloading #{img}"
		File.write(picdir + img.split("/").last , Net::HTTP.get(URI $baseurl+img))
	end
when :range
	for pnum_iter in (pagenum_start..pagenum_end)
		page = Nokogiri::HTML Net::HTTP.get(URI $baseurl+"?search=#{tags_esc}&page=#{pnum_iter}")
		imgs = page.css('div.thumb')
		imgs.empty?&&abort("Page number to large(or nothing found).")
		imgs = imgs.map{|i|"/i/#{mode_uri}/#{i.children.first.children.first.attributes["href"].value.split("/").last}.png"}
		imgs.each_with_index do |img,ind|
			(puts("(Page#{pnum_iter}|#{ind+1}/#{imgs.length}) Skipping #{img} (already exists)");next) if File.exists?(picdir+img.split("/").last)
			puts "(Page#{pnum_iter}|#{ind+1}/#{imgs.length}) Downloading #{img}"
			File.write(picdir + img.split("/").last , Net::HTTP.get(URI $baseurl+img))
		end
	end
when :all
	page = Nokogiri::HTML Net::HTTP.get(URI $baseurl+"?search=#{tags_esc}&page=1")
	imgs = page.css('div.thumb')
	pagenum_start = 1
	pagenum_end = page.css('span.pagelist').children.last.children.last.to_s.to_i
	for pnum_iter in (pagenum_start..pagenum_end)
		page = Nokogiri::HTML Net::HTTP.get(URI $baseurl+"?search=#{tags_esc}&page=#{pnum_iter}")
		imgs = page.css('div.thumb')
		imgs.empty?&&abort("Page number to large(or nothing found).")
		imgs = imgs.map{|i|"/i/#{mode_uri}/#{i.children.first.children.first.attributes["href"].value.split("/").last}.png"}
		imgs.each_with_index do |img,ind|
			(puts("(Page#{pnum_iter}|#{ind+1}/#{imgs.length}) Skipping #{img} (already exists)");next) if File.exists?(picdir+img.split("/").last)
			puts "(Page#{pnum_iter}|#{ind+1}/#{imgs.length}) Downloading #{img}"
			resp = Net::HTTP.get_response(URI $baseurl+img)
			if resp.code.to_s[0]!="2"
				puts "(Page#{pnum_iter}|#{ind+1}/#{imgs.length}) ERROR: #{img} RETURNED HTTP #{resp.code}"
				next
			end
			File.write(picdir + img.split("/").last , resp.body)
		end
	end
end
