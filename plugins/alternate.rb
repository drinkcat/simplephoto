class Alternate
    attr_reader :accel
    
    def initialize(callback)
        @accel = [ "a", "x" ]
        @image = nil
        @callback = callback
    end

    def getwidget()
        box = Gtk::VBox.new(false, 0)
        @list = Gtk::Label.new()
        box.pack_start(Gtk::Label.new("Alternates:"), false, false, 0)
        box.pack_start(@list, false, false, 0)
        return box
    end

    def activate(key)
        return if (!@image)
        if (key == 'a') then
          @image.nextalt()
        elsif (key == 'x') then
          @image.removealt()
        end
        @callback.updateimage()
    end

    def imagechanged(image)
        @image = image
        alt = [ @image.filename ]
        @image.alt.each{ |a| alt << a.filename }
        alt[@image.defaultalt+1] = ">" + alt[@image.defaultalt+1]
        @list.text = alt.join("\n")
    end
end
