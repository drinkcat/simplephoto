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
        @desctext.grab_focus
    end

    def imagechanged(image)
        @image.description = @desctext.text if (@image)
        @image = image
        @desctext.text = @image.description if (@image)
    end
end
