class ExternalEditor
    attr_reader :accel
    
    def initialize(callback)
        @accel = [ "g" ]
        @image = nil
        @callback = callback
    end

    def getwidget()
        return nil
    end

    def imagechanged(image)
        @image = image
    end

    def activate(key)
        alt = @image.getcurrentalt(false)
        puts "alt=#{alt}"
        puts "#{alt.filename} + #{@image.filename}" if (alt)
        if (!alt || alt.filename == @image.filename) then
            @image.createalt(true)
            alt = @image.getcurrentalt(false)
        end
        cmd = "gimp #{@image.directory}/#{alt.filename}"
        puts "Running #{cmd}"
        system(cmd);
    end
end
