
class Description
    attr_reader :accel
    
    def initialize(callback)
        @accel = [ "d" ]
        @image = nil
        @callback = callback
    end

    def getwidget()
        box = Gtk::VBox.new(false, 0)
        @desctext = Gtk::Entry.new()
        @desctext.signal_connect("activate") {|adj| @callback.focus_image() }
        box.pack_start(Gtk::Label.new("Description:"), false, false, 0)
        box.pack_start(@desctext, false, false, 0)
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


