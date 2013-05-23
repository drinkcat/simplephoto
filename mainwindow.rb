class MainWindow < Gtk::Window
    def initialize()
        super(Gtk::Window::TOPLEVEL)

        @singlephotomode = false

        @database = Database.new("/home/nicolas/photos/origs/2013/05a_random")
        #@photolist.set_directory("/home/nicolas/photos/origs/2013/04d_vietnam")

        set_title  "Simple Photo"
        border_width = 10
        set_size_request(800, 600)
        signal_connect('delete_event') {
            Gtk.main_quit
            Thread.list.each {|t| t.kill }
        }

        leftpaned = Gtk::VPaned.new

        @dirtree = DirTree.new("/home/nicolas/photos/origs")
        leftpaned.add1(@dirtree)
        @dirtree.set_size_request(-1, 800)

        infobox = Gtk::VBox.new(false, 0)
        @desclabel = Gtk::Label.new()
        infobox.pack_start(Gtk::Label.new("Description:"), false, false, 0)
        infobox.pack_start(@desclabel, false, false, 0)

        infoscrollwin = Gtk::ScrolledWindow.new
        #infoscrollwin.border_width = 5
        infoscrollwin.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
        @infostore = Gtk::ListStore.new(String, String)
        infotree = Gtk::TreeView.new(@infostore)

        col = Gtk::TreeViewColumn.new("Key", Gtk::CellRendererText.new, :text => 0)
        col.set_resizable(true)
        col.set_sizing(Gtk::TreeViewColumn::FIXED)
        col.set_fixed_width(150)
        infotree.append_column(col)

        col = Gtk::TreeViewColumn.new("Value", Gtk::CellRendererText.new, :text => 1)
        infotree.append_column(col)

        infoscrollwin.add(infotree)
        infoscrollwin.set_size_request(-1, 200)
        infobox.pack_end(infoscrollwin, true, true, 0)

        leftpaned.pack2(infobox, true, false)
        infobox.set_size_request(-1, 200)

        scrollwin = Gtk::ScrolledWindow.new
        scrollwin.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
        
        @photolist = PhotoList.new()
        @photolist.set_database(@database)
        scrollwin.add(@photolist)

        @photolist.signal_connect("selection-changed") { oniconselect() }

        @photolist.signal_connect("item-activated") { |p, path| onicondoubleclick(path) }

        @displayimage = nil
        @singleimage = Gtk::Image.new

        @scrollwinimage = Gtk::ScrolledWindow.new
        @scrollwinimage.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
        @scrollwinimage.add_with_viewport(@singleimage)

        toppaned = Gtk::HPaned.new
        leftpaned.set_size_request(300, -1)
        toppaned.pack1(leftpaned, true, false)
        scrollwin.set_size_request(800, -1)

        @rightnotebook = Gtk::Notebook.new
        @rightnotebook.show_border = false
        @rightnotebook.show_tabs = false
        @rightnotebook.append_page(scrollwin)
        @rightnotebook.append_page(@scrollwinimage)
        toppaned.add2(@rightnotebook)

        add(toppaned)

        add_events(Gdk::Event::KEY_PRESS)

        signal_connect("key-press-event") do |w, e|
            keyname = Gdk::Keyval.to_name(e.keyval)
            if (keyname == "Escape") then
                switchdisplaymode(false)
            end

            if (@singlephotomode) then
                
                if (keyname == "Left") then
                    ix = @database.images.index(@displayimage)
                    if (ix > 0) then
                        @displayimage = @database.images[ix-1]
                        displayimage()
                    end
                elsif (keyname == "Right") then
                    ix = @database.images.index(@displayimage)
                    if (ix < @database.images.length-1) then
                        @displayimage = @database.images[ix+1]
                        displayimage()
                    end
                end
            end
            puts "#{e.keyval}, Gdk::Keyval::GDK_#{Gdk::Keyval.to_name(e.keyval)}"
        end
    end

    def switchdisplaymode(singlephoto)
        return if (singlephoto == @singlephotomode)

        @singlephotomode = singlephoto

        if (@singlephotomode) then
            @rightnotebook.set_page(1)
        else
            @rightnotebook.set_page(0)
        end
    end

    def oniconselect()
      if (@photolist.selected_items.length == 1) then
        model = @photolist.model
        im = model.get_value(model.get_iter(@photolist.selected_items[0]), 0)

        @infostore.clear
        keys = (im.exif.keys & FIRST_EXIF) + (im.exif.keys - FIRST_EXIF)
        keys.each{|key|
            iter = @infostore.append
            iter[0] = key.to_s
            iter[1] = im.exif[key].to_s
        }
      end
    end

    def onicondoubleclick(path)
        model = @photolist.model
        @displayimage = model.get_value(model.get_iter(path), 0)
        displayimage()
    end

    def displayimage()
       image = Magick::Image::read(@displayimage.fullname).first
        
        pix_w = image.columns
        pix_h = image.rows
        r1 = @scrollwinimage.allocation.width/pix_w.to_f
        r2 = @scrollwinimage.allocation.height/pix_h.to_f
        simage = image.scale([r1, r2].min)

        @singleimage.pixbuf = Gdk::Pixbuf.new(simage.export_pixels_to_str(), Gdk::Pixbuf::COLORSPACE_RGB,
                            false, 8, simage.columns, simage.rows, simage.columns*3)
        switchdisplaymode(true)
    end
end

