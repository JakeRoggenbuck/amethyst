#!/usr/bin/env ruby
require 'http'
require 'json'
require 'optparse'
require 'ostruct'

package_upstream = 'https://jakeroggenbuck.github.io/impulse/list.json'
config_directory = '/home/jake/.config/amethyst/'

def update_list(url, directory)
  package_list = HTTP.get url
  package_list = JSON.parse(package_list)
  File.open(directory + 'list.json', 'w') { |file| file.write(package_list) }
end

def directory_exists(directory)
  unless File.directory?(directory)
    Dir.mkdir directory
  end
end

def list_exists(url, directory)
  puts directory + 'list.json'
  unless File.file?(directory + 'list.json')
    update_list(url, directory)
  end
end

directory_exists(config_directory)
list_exists(package_upstream, config_directory)

options = OpenStruct.new
OptionParser.new do |opt|
  opt.on('-U', '--update', 'Update list') { |o| options.update = o }
  opt.on('-S', '--search SEARCH', 'Search cached list') { |o| options.search = o }
  opt.on('-I', '--install INSTALL', 'Install package') { |o| options.install = o }
end.parse!

if options.update
  update_list(package_upstream, config_directory)
end
