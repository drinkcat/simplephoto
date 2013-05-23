#!/usr/bin/env ruby -d
# All in Paned
# File navigator on left (TreeView)
# Exif on left bottom (?)
# Scrollwindow on the right

DEFAULT_IMAGE_WIDTH = 200
DEFAULT_IMAGE_HEIGHT = DEFAULT_IMAGE_WIDTH*3/4
FIRST_EXIF = [ "FocalLength", "ExposureTime", "FNumber", "ISO", "WhiteBalance", "Flash" ]

require 'gtk2'
require 'thread'
require 'RMagick'

require "./photolist.rb"
require "./dirtree.rb"
require "./mainwindow.rb"
require "./database.rb"

window = MainWindow.new()
window.show_all
Gtk.main

