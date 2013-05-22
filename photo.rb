#!/usr/bin/env ruby
# All in Paned
# File navigator on left (TreeView)
# Exif on left bottom (?)
# Scrollwindow on the right

DEFAULT_IMAGE_WIDTH = 150

require 'gtk2'
require 'thread'
require 'RMagick'

require "./photolist.rb"

window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
window.set_title  "Panes"
window.border_width = 10
window.set_size_request(800, 600)
window.signal_connect('delete_event') {
    Gtk.main_quit
    Thread.list.each {|t| t.kill }
}

leftpaned = Gtk::VPaned.new

scrollwin = Gtk::ScrolledWindow.new
scrollwin.border_width = 5
scrollwin.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
 
photolist = PhotoList.new()
photolist.set_directory("/home/nicolas/photos/origs/2013/05a_random")
# Pack objects and show them all
scrollwin.add(photolist)
#vbox.pack_start(scrollwin)

toppaned = Gtk::HPaned.new
toppaned.add1(leftpaned)
toppaned.add2(scrollwin)

window.add(toppaned)
window.show_all
Gtk.main

