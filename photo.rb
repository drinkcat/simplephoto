#!/usr/bin/env ruby

require './config.rb'

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

