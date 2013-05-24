
DEFAULT_IMAGE_WIDTH = 200
DEFAULT_IMAGE_HEIGHT = DEFAULT_IMAGE_WIDTH*3/4
FIRST_EXIF = [ "FocalLength", "ExposureTime", "FNumber", "ISO", "WhiteBalance", "Flash" ]


require 'gtk2'
require "./database.rb"

@database = Database.load("/home/nicolas/photos/origs/2013/05a_random")

puts @database.to_yaml

@database.save
