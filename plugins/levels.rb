
LEVELS_HEIGHT=100
LEVELS_WIDTH=260
LEVELS_XOFFSET=2
LEVELS_YBORDERTOP=2
LEVELS_YBORDERBOTTOM=10

class Levels
    attr_reader :accel
    
    def initialize(callback)
        @accel = [ "l" ]
        @image = nil
        @callback = callback
        @histogrampixmap = nil
    end

    def getwidget()
        box = Gtk::VBox.new(false, 0)
        box.pack_start(Gtk::Label.new("Levels:"), false, false, 0)
        @histogram = Gtk::Image.new()
        @histogram.set_size_request(LEVELS_WIDTH, LEVELS_HEIGHT)
        box.pack_start(@histogram, false, false, 0)

        @blacklabel = Gtk::Label.new("Black: " + 0.to_s)
        box.pack_start(@blacklabel, false, false, 0)
        @blackadj = Gtk::Adjustment.new(0,0,255,1,16,0)
        blackadjscroll = Gtk::HScrollbar.new(@blackadj)
        @blackadj.signal_connect("value-changed") {|adj| adjust() }
        box.pack_start(blackadjscroll, false, false, 0)

        @whitelabel = Gtk::Label.new("White: " + 255.to_s)
        box.pack_start(@whitelabel, false, false, 0)
        @whiteadj = Gtk::Adjustment.new(255,0,255,1,16,0)
        whiteadjscroll = Gtk::HScrollbar.new(@whiteadj)
        @whiteadj.signal_connect("value-changed") {|adj| adjust() }
        box.pack_start(whiteadjscroll, false, false, 0)

        return box
    end

    def adjust()
        return if (!@image)

        activate(nil) if (!@levelmod)

        black = @blackadj.value.round.to_i
        @levelmod.black = black
        @blackadj.value = black

        white = @whiteadj.value.round.to_i
        @levelmod.white = white
        @whiteadj.value = white

        updatetext()

        @callback.updateimage()
    end

    def updatetext()
        @blacklabel.text = "Black: " + (@levelmod ? @levelmod.black.to_s : "0")
        @whitelabel.text = "White: " + (@levelmod ? @levelmod.white.to_s : "255")
    end

    def activate(key)
        alt = @image.getcurrentalt(true)
        if (!@levelmod) then
            @levelmod = LevelModifier.new(0, 255)
            alt.modifiers << @levelmod
        end
    end

    def imagechanged(image)
        @image = nil
        alt = image.getcurrentalt(false)
        @levelmod = alt ? alt.modifiers.find{|x| x.class == LevelModifier} : nil
        if (@levelmod) then
            #puts "L:#{@levelmod.black}/#{@levelmod.white}"
            @blackadj.value = @levelmod.black
            @whiteadj.value = @levelmod.white
        else
            @blackadj.value = 0
            @whiteadj.value = 255
        end
        updatetext()
        @image = image

        if (!@histogrampixmap) then
            window = @histogram.get_ancestor(Gtk::Window).window
            @histogrampixmap = Gdk::Pixmap.new(window, LEVELS_WIDTH, LEVELS_HEIGHT, -1)
        end
        gc = Gdk::GC.new(@histogrampixmap)
        gc.rgb_fg_color = Gdk::Color.parse("#FFFFFF")
        @histogrampixmap.draw_rectangle(gc, true, 0, 0, LEVELS_WIDTH, LEVELS_HEIGHT)
        gc.rgb_fg_color = Gdk::Color.parse("#000000")
        @histogrampixmap.draw_rectangle(gc, false, 0, 0, LEVELS_WIDTH-1, LEVELS_HEIGHT-1)
        
        scale = (LEVELS_HEIGHT-LEVELS_YBORDERBOTTOM-LEVELS_YBORDERTOP)/(@image.histogram.sort[253]*1.1)

        gc.rgb_fg_color = Gdk::Color.parse("#000000")
        @image.histogram.each_index{ |i|
            @histogrampixmap.draw_line(gc,
                    LEVELS_XOFFSET+i, LEVELS_HEIGHT-LEVELS_YBORDERBOTTOM,
                    LEVELS_XOFFSET+i, LEVELS_HEIGHT-LEVELS_YBORDERBOTTOM-@image.histogram[i]*scale)
        }
        
        if (@levelmod) then
            gc.rgb_fg_color = Gdk::Color.parse("#000000")
            
            @histogrampixmap.draw_line(gc,
                        LEVELS_XOFFSET+@levelmod.black, LEVELS_HEIGHT-LEVELS_YBORDERBOTTOM,
                        LEVELS_XOFFSET+@levelmod.black, LEVELS_HEIGHT-2)

            @histogrampixmap.draw_line(gc,
                        LEVELS_XOFFSET+@levelmod.white, LEVELS_HEIGHT-LEVELS_YBORDERBOTTOM,
                        LEVELS_XOFFSET+@levelmod.white, LEVELS_HEIGHT-2)

        end
        @histogram.pixmap = @histogrampixmap
    end
end

class LevelModifier
    attr_accessor :black
    attr_accessor :white
    
    def initialize(black, white)
        @black = black
        @white = white
    end

    def apply(image)
        image.level(black*Magick::QuantumRange/255, white*Magick::QuantumRange/255, 1.0)
    end
end

