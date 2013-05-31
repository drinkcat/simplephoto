    # Database of current images

require 'yaml'
require 'json'
require 'gtk2'
require 'RMagick'
require 'fileutils'

$blank = Gdk::Pixbuf.new(Gdk::Pixbuf::COLORSPACE_RGB, false, 8, DEFAULT_IMAGE_WIDTH, DEFAULT_IMAGE_WIDTH*3/4)

class Database
    private_class_method :new

    def Database.load(directory)
        db = nil
        if File.exists?(directory + '/simplephoto.yaml')
            db = YAML::load( File.read(directory + '/simplephoto.yaml') )
            db.postload(directory)
        else
            db = new(directory)
        end
        db.addimages()
        db
    end

    attr_reader :directory
    attr_reader :images

    def encode_with coder
        coder['images'] = @images
    end

    def init_with coder
        @images = coder['images']
        @directory = nil
        @backup = false
    end

    def initialize(directory)
        @directory = directory
        @images = []
        @backup = false
    end

    def postload(directory)
        @directory = directory
        @images.each{|im| im.directory = directory}   
    end

    def addimages()
        dirlist = Dir.new(@directory).to_a.sort!
        dirlist.each{|filename|
            next if (filename.upcase !~ /.*JPG/)
            if (!@images.any?{|im| im.filename == filename}) then
                @images << Image.new(@directory, filename)
            end
        }
        # Remove references to non-existing files
        @images.reject!{|im|
            !dirlist.any?{|file| file == im.filename}
        }
    end

    def save()
        if (!@backup) then
            if (File.exists?(directory + '/simplephoto.yaml')) then
                date = DateTime.now.strftime("%Y%jT%H%MZ")
                FileUtils.mv(directory + '/simplephoto.yaml', directory + "/simplephoto.yaml.bkp-#{date}")
            end
            @backup = true
        end
        File.open(directory + '/simplephoto.yaml', 'w') { |f|
            f.print self.to_yaml
        }
    end
end

class Image
    attr_reader :filename
    attr_reader :description
    attr_reader :rank
    attr_reader :alt
    attr_reader :defaultalt

    attr_accessor :directory

    # Non-persistent
    # GDK pixbuf thumbnail
    attr_accessor :thumbnail
    # Display in filelist?
    attr_accessor :display

    attr_accessor :histogram

    def encode_with coder
        coder['filename'] = @filename
        coder['description'] = @description
        coder['rank'] = @rank
        coder['alt'] = @alt
        coder['defaultalt'] = @defaultalt
    end

    def init_with coder
        @filename = coder['filename']
        @description = coder['description']
        @rank = coder['rank']
        @alt = coder['alt']
        @defaultalt = coder['defaultalt']
        initdefault()
    end

    def initialize(directory, filename)
        @directory = directory
        @filename = filename
        @description = ""
        @rank = 0
        initdefault()
    end

    def initdefault()
        @thumbnail = $blank
        @exif = nil
        @display = true
        @alt = [] if (!@alt)
        @defaultalt = -1 if (!@defaultalt)
        @cacheinfo = nil
    end

    def exif
        return @exif if (@exif)
        
        exiftool = `exiftool -json #{self.fullname}`
        @exif = JSON.parse(exiftool)[0]
        
        return @exif
    end

    def genthumbnail(force = false)
        return if (@thumbnail != $blank)

        # Hack to make sure thumbnail is generated in another process
        results = Parallel.map([self]) do |im|
            image = Magick::Image::read(im.fullname).first
            image.auto_orient!

            pix_w = image.columns
            pix_h = image.rows
            r1 = DEFAULT_IMAGE_WIDTH/pix_w.to_f
            r2 = DEFAULT_IMAGE_HEIGHT/pix_h.to_f
            out = [im.fullname, image.thumbnail([r1, r2].min)]
            image.destroy!
            out
        end

        scaled_pix = results[0][1]
        @thumbnail = Gdk::Pixbuf.new(scaled_pix.export_pixels_to_str(), Gdk::Pixbuf::COLORSPACE_RGB,
                        false, 8, scaled_pix.columns, scaled_pix.rows, scaled_pix.columns*3)
        scaled_pix.destroy!

        #FIXME: Make sure thumbnail is updated in the listmodel of photolist.rb
    end

    #FIXME: Clear up cache when necessary
    def genfullimage(width, height)
        cacheinfo = [fullname, width, height]

        if (cacheinfo != @cacheinfo) then
            image = Magick::Image::read(fullname).first
            image.auto_orient!

            pix_w = image.columns
            pix_h = image.rows
            r1 = width/pix_w.to_f
            r2 = height/pix_h.to_f
            simage = image.scale([r1, r2].min)

            hist = (0..255).map{0}

            #.quantize(256, Magick::GRAYColorspace, Magick::NoDitherMethod)
            simage.thumbnail(200, 200).color_histogram.each{|pixel, count|
                hist[(pixel.intensity*255/Magick::QuantumRange).round.to_i] += count
            }

            sum = hist.inject(0){|sum, t| sum + t}
            @histogram = hist.map{|x| x.to_f/sum}

            @imagecache = simage
            @cacheinfo = cacheinfo
        else
            simage = @imagecache
        end

        if (@defaultalt > -1) then
            @alt[@defaultalt].modifiers.each{|mod|
                simage = mod.apply(simage)
            }
        end

        simage
    end

    def export(outfile)
        image = Magick::Image::read(fullname).first

        if (@defaultalt > -1) then
            @alt[@defaultalt].modifiers.each{|mod|
                image = mod.apply(image)
            }
        end

        image.write(outfile)
        image.destroy!
        GC.start()
    end

    def fullname
        @directory + "/" + ((@defaultalt == -1) ? @filename : @alt[@defaultalt].filename)
    end

    def description=(desc)
        @description = desc
    end

    def rank=(rank)
        @rank = rank
    end

    def getcurrentalt(create)
        if (@defaultalt == -1) then
            if (create) then
                newalt = ImageAlternate.new(@filename)
                @alt << newalt
                @defaultalt = @alt.length-1
            else
                return nil
            end
        end
        @alt[@defaultalt]
    end
end

# Reference to a modified image
class ImageAlternate
    attr_reader :filename
    attr_reader :modifiers
    
    def initialize(filename)
        @filename = filename
        @modifiers = []
    end
end

