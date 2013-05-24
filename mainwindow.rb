class MainWindow < Gtk::Window
    def initialize()
        super(Gtk::Window::TOPLEVEL)

        @singlephotomode = false

        set_title  "Simple Photo"
        border_width = 10
        set_size_request(800, 600)
        signal_connect('delete_event') {
            @database.save if (@database)
            Gtk.main_quit
            Thread.list.each {|t| t.kill }
        }

        leftpaned = Gtk::VPaned.new

        @dirtree = DirTree.new("/home/nicolas/photos/origs")
        @dirtree.set_size_request(-1, 800)

        @plugins = []
        pluginsbox = Gtk::VBox.new(false, 0)

        PLUGINS.each{|key, value|
            require "./plugins/#{key}"
            plugin = eval("#{value}.new(self)")
            widget = plugin.getwidget()
            pluginsbox.pack_start(widget, false, false, 0)
            @plugins << plugin
        }

        @pluginsmulti = []
        # FIXME: Add support for widgets

        PLUGINS_MULTI.each{|key, value|
            require "./plugins/#{key}"
            plugin = eval("#{value}.new(self)")
            @pluginsmulti << plugin
        }

        @lefttopnotebook = Gtk::Notebook.new
        @lefttopnotebook.show_border = false
        @lefttopnotebook.show_tabs = false
        @lefttopnotebook.append_page(@dirtree)
        @lefttopnotebook.append_page(pluginsbox)

        leftpaned.add1(@lefttopnotebook)

        infobox = Gtk::VBox.new(false, 0)
        @desclabel = Gtk::Label.new()
        @filenamelabel = Gtk::Label.new()
        infobox.pack_start(Gtk::Label.new("Filename:"), false, false, 0)
        infobox.pack_start(@filenamelabel, false, false, 0)
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

        @scrollwinimage.signal_connect('button-press-event') { |w|
            #puts "Button!"
            @scrollwinimage.grab_focus
        }

        @scrollwinimage.add_events(Gdk::Event::KEY_PRESS)

        @scrollwinimage.signal_connect("key-press-event") do |w, e|
            keyname = Gdk::Keyval.to_name(e.keyval)
            if (keyname == "Escape") then
                switchdisplaymode(false)
                @photolist.update()
            end

            if (@singlephotomode) then
                if (keyname == "Left") then
                    ix = @database.images.index(@displayimage)
                    if (ix > 0) then
                        @displayimage = @database.images[ix-1]
                        displayfullimage()
                    end
                elsif (keyname == "Right") then
                    ix = @database.images.index(@displayimage)
                    if (ix < @database.images.length-1) then
                        @displayimage = @database.images[ix+1]
                        displayfullimage()
                    end
                else
                    @plugins.each{|plugin|
                        if (plugin.accel.include?(keyname)) then
                            plugin.activate(keyname)
                        end
                    }
                end
            end
            #puts "#{e.keyval}, Gdk::Keyval::GDK_#{Gdk::Keyval.to_name(e.keyval)}"
            # Prevent key events from going further
            true
        end

        @photolist.add_events(Gdk::Event::KEY_PRESS)

        @photolist.signal_connect("key-press-event") do |w, e|
            keyname = Gdk::Keyval.to_name(e.keyval)
            ret = false
            @pluginsmulti.each{|pluginmulti|
                if (pluginmulti.accel.include?(keyname)) then
                    pluginmulti.activate(keyname)
                    ret = true
                end
            }
            ret
        end

        @database = Database.load("/home/nicolas/photos/origs/2013/05b_suzhou")
        @photolist.set_database(@database)
        @pluginsmulti.each{ |plugin| plugin.dbchanged(@database) }

        #Display first
        #@displayimage = @database.images[0]
        #displayfullimage()
    end

    def switchdisplaymode(singlephoto)
        return if (singlephoto == @singlephotomode)

        @singlephotomode = singlephoto

        if (@singlephotomode) then
            @rightnotebook.set_page(1)
            @lefttopnotebook.set_page(1)
        else
            @rightnotebook.set_page(0)
            @lefttopnotebook.set_page(0)
        end
    end

    def oniconselect()
        if (@photolist.selected_items.length == 1) then
            model = @photolist.model
            @displayimage = model.get_value(model.get_iter(@photolist.selected_items[0]), 0)
        else
            @displayimage = nil
        end

        displayimageinfo();
    end

    def onicondoubleclick(path)
        model = @photolist.model
        @displayimage = model.get_value(model.get_iter(path), 0)
        displayfullimage()
    end

    def displayimageinfo()
        @infostore.clear
        if (@displayimage) then
            keys = (@displayimage.exif.keys & FIRST_EXIF) + (@displayimage.exif.keys - FIRST_EXIF)
            keys.each{|key|
                iter = @infostore.append
                iter[0] = key.to_s
                iter[1] = @displayimage.exif[key].to_s
            }
            @filenamelabel.text = @displayimage.filename;
            @desclabel.text = @displayimage.description;
        else
            @filenamelabel.text = "";
            @desclabel.text = "";
        end
    end

    # FIXME: Rescale image on window size change
    def displayfullimage()
        displayimageinfo()

        #FIXME: First display scaled thumbnail, then async load of other image

        simage = @displayimage.genfullimage(@scrollwinimage.allocation.width, @scrollwinimage.allocation.height)

        @singleimage.pixbuf = Gdk::Pixbuf.new(simage.export_pixels_to_str(), Gdk::Pixbuf::COLORSPACE_RGB,
                            false, 8, simage.columns, simage.rows, simage.columns*3)

        @plugins.each{ |plugin| plugin.imagechanged(@displayimage) }

        switchdisplaymode(true)
    end

    def getcurrentimage()
        return @displayimage
    end

    def updateimage()
        displayfullimage()
    end

    def updateimagelist()
        @photolist.update()
    end
end

