#!/usr/bin/env ruby
require 'http'
require 'json'
require 'optparse'
require 'ostruct'
require 'rubygems/package'
require 'zlib'
require 'fileutils'

package_upstream = 'https://jakeroggenbuck.github.io/impulse/'
config_directory = '/home/jake/.config/amethyst/'

def update_list(url, directory)
  package_list = HTTP.get url
  package_list = JSON.parse(package_list)
  File.open(directory + 'list.json', 'w') { |file| file.write(package_list) }
end

class Package
  def initialize(url, name, is_verbose)
    @package_name = name
    @verbose_install = is_verbose
    @tar_name = name + '.tar.gz'
    @tar_url = url + @tar_name
    @tar_full_path = '/tmp/' + @tar_name
    @stage_dir = '/tmp/' + @package_name
  end
  def download()
    if @verbose_install
      puts 'Downloading from ' + @tar_url
    end
    package = HTTP.get @tar_url
    File.open(@tar_full_path, 'w') { |file| file.write(package) }
    if @verbose_install
      puts 'Downloaded successfully'
    end
  end
  def install()
    tar = File.open(@tar_full_path, 'rb')
    if File.directory?(@stage_dir)
      FileUtils.rm_rf(@stage_dir)
    end
    Dir.mkdir '/tmp/' + @package_name
    tar_extract = Gem::Package.new("").extract_tar_gz(tar, @stage_dir)
    if @verbose_install
      puts 'Extracted successfully'
    end
    Dir.chdir(@stage_dir)
    tar_dir = Dir.glob('*').select { |f| File.path f }
    Dir.chdir(tar_dir[0])
    print 'See diff? [Y/n] '
    get_diff = gets
    if get_diff
      system('less impulse.build')
    end
    print 'Finish install? [Y/n] '
    finish_install = gets
    if finish_install 
      system('sudo sh impulse.build')
    end
    if @verbose_install
      puts 'Installed successfully'
    end
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
