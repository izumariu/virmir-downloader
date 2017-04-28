#!/usr/bin/env ruby

load 'startup.rb' # init libs and stuff

usgstr = "USAGE: ruby #{__FILE__} [finished|sketches|inked|real|cards] [<page>|<start>-<end>|all] [LOW|hi]"
gal,pagenum,mode = ARGV
(gal&&pagenum&&mode)||abort(usgstr)
ARGV.clear

$galurl = $baseurl+"/gallery/"


if pagenum.match(/^\d+$/)
	pagenum_mode = :single
elsif pagenum.match(/^\d+-\d+$/)
	pagenum_mode = :range
	pagenum_start = pagenum.match(/^(\d+)/)[1].to_s.to_i
	pagenum_end = pagenum.match(/(\d+)$/)[1].to_s.to_i
else
	pagenum_mode = :all
end

galitems = usgstr.split.select{|i|i.match %r{^\[.+\]$}}[0].split("").drop(1).join.reverse.split("").drop(1).join.reverse.split("|")
galitems.include?(gal.downcase)||abort(usgstr)

$galnum = galitems.index(gal.downcase)+1

picdir = "pics/#{gal.downcase}/#{mode.downcase=="hi" ? "full" : "standard"}/"

Dir.mkdir("pics") rescue nil
Dir.mkdir(picdir.split("/")[0,2].join("/")) rescue nil
Dir.mkdir(picdir) rescue nil

case pagenum_mode
when :single
	page = Nokogiri::HTML Net::HTTP.get(URI $galurl.to_s+$galnum.to_s+"?page=#{pagenum}")
	imgs = page.css('div.thumb')
	imgs.empty?&&abort("Page number to large.")
	imgs = imgs.map{|i|"/i/#{picdir.split("/")[2]}/#{i.children.first.children.first.attributes["href"].value.split("/").last}.png"}
	imgs.each_with_index do |img,ind|
		(puts("(#{ind+1}/#{imgs.length}) Skipping #{img} (already exists)");next) if File.exists?(picdir+img.split("/").last)
		puts "(#{ind+1}/#{imgs.length}) Downloading #{img}"
		File.write(picdir + img.split("/").last , Net::HTTP.get(URI $baseurl+img))
	end
when :range
	for pnum_iter in (pagenum_start..pagenum_end)
		page = Nokogiri::HTML Net::HTTP.get(URI $galurl.to_s+$galnum.to_s+"?page=#{pnum_iter}")
		imgs = page.css('div.thumb')
		imgs.empty?&&abort("Page number to large.")
		imgs = imgs.map{|i|"/i/#{picdir.split("/")[2]}/#{i.children.first.children.first.attributes["href"].value.split("/").last}.png"}
		imgs.each_with_index do |img,ind|
			(puts("(Page#{pnum_iter}|#{ind+1}/#{imgs.length}) Skipping #{img} (already exists)");next) if File.exists?(picdir+img.split("/").last)
			puts "(Page#{pnum_iter}|#{ind+1}/#{imgs.length}) Downloading #{img}"
			File.write(picdir + img.split("/").last , Net::HTTP.get(URI $baseurl+img))
		end
	end
when :all
	page = Nokogiri::HTML Net::HTTP.get(URI $galurl.to_s+$galnum.to_s+"?page=1")
	pagenum_start = 1
	pagenum_end = page.css('span.pagelist').children.last.children.last.to_s.to_i
	for pnum_iter in (pagenum_start..pagenum_end)
		page = Nokogiri::HTML Net::HTTP.get(URI $galurl.to_s+$galnum.to_s+"?page=#{pnum_iter}")
		imgs = page.css('div.thumb')
		imgs.empty?&&abort("Page number to large.")
		imgs = imgs.map{|i|"/i/#{picdir.split("/")[2]}/#{i.children.first.children.first.attributes["href"].value.split("/").last}.png"}
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
