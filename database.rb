# Database of current images

require 'json'

$blank = Gdk::Pixbuf.new(Gdk::Pixbuf::COLORSPACE_RGB, false, 8, DEFAULT_IMAGE_WIDTH, DEFAULT_IMAGE_WIDTH*3/4)

class Database
    attr_reader :directory
    attr_reader :images

    def initialize(directory)
        @directory = directory
        
        @images = []
        Dir.new(directory).to_a.sort!.each{|filename|
            next if (filename.upcase !~ /.*JPG/)
            @images << Image.new(directory, filename)
        }
    end
end

class Image
    attr_reader :filename
    attr_reader :fullname

    # GDK pixbuf thumbnail
    attr_accessor :thumbnail

    def initialize(directory, filename)
        @fullname = directory + "/" + filename
        @filename = filename

        @thumbnail = $blank
        @exif = nil
    end

    def exif
        return @exif if (@exif)
        
        exiftool = `exiftool -json #{@fullname}`
        @exif = JSON.parse(exiftool)[0]
        
        return @exif
    end
end
