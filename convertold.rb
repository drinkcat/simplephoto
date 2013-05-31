#!/usr/bin/env ruby

DEFAULT_IMAGE_WIDTH = 200
DEFAULT_IMAGE_HEIGHT = DEFAULT_IMAGE_WIDTH*3/4
FIRST_EXIF = [ "FocalLength", "ExposureTime", "FNumber", "ISO", "WhiteBalance", "Flash" ]

if (ARGV.length != 2) then
    puts "convertold.rb directory commentsfile"
end

require "./database.rb"

@database = Database.load(ARGV[0])

File.open(ARGV[1]).each{|line|
    chunks = line.chomp.split(/\|/)
    chunks[1] = "" if (!chunks[1])
    comment = chunks[1].strip
    im = @database.images.find{|im| im.filename == chunks[0]}
    if (!im) then
        puts "Cannot find #{chunks[0]}."
        next
    end
    im.rank = 3
    im.description = chunks[1]
}

@database.save()
