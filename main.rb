#!/usr/bin/env ruby
require 'http'
require 'json'
require 'optparse'
require 'ostruct'
require 'rubygems/package'
require 'zlib'

package_upstream = 'https://jakeroggenbuck.github.io/impulse/'
config_directory = '/home/jake/.config/amethyst/'

def update_list(url, directory)
  package_list = HTTP.get url
  package_list = JSON.parse(package_list)
  File.open(directory + 'list.json', 'w') { |file| file.write(package_list) }
end

class Package
  def initialize(url, name, is_verbose)
    @package_url = url + name
    @package_name = name
    @verbose_install = is_verbose
  end
  def download()
    puts @package_url
    package = HTTP.get @package_url + '.tar.gz'
    File.open('/tmp/' + @package_name + '.tar.gz', 'w') { |file| file.write(package) }
  end
  def install()
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open('/tmp/' + @package_name + '.tar.gz'))
    tar_extract.rewind
    if @verbose_install
      tar_extract.each do |entry|
        puts entry.full_name
      end
    end
    tar_extract.close
  end
end

def directory_exists(directory)
  unless File.directory?(directory)
    Dir.mkdir directory
  end
end

def list_exists(url, directory)
  unless File.file?(directory + 'list.json')
    update_list(url, directory)
  end
end

directory_exists(config_directory)
list_exists(package_upstream + 'list.json', config_directory)

options = OpenStruct.new
OptionParser.new do |opt|
  opt.on('-U', '--update', 'Update list') { |o| options.update = o }
  opt.on('-S', '--search SEARCH', 'Search cached list') { |o| options.search = o }
  opt.on('-I', '--install INSTALL', 'Install package') { |o| options.install = o }
  opt.on('-V', '--verbose', 'Verbose output') { |o| options.verbose = o }
end.parse!

if options.update
  update_list(package_upstream + 'list.json', config_directory)
end

if options.install
  pack = Package.new(package_upstream, options.install, options.verbose)
  pack.download() 
  pack.install() 
end
