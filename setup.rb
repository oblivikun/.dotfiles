require 'optparse'
require 'uri'
require 'tempfile'
require 'fileutils'
require 'net/http'
require 'zlib'
require 'rubygems/package'
require 'open3'

$privilege_escalator = 'sudo'

def install_quicklisp


  url = URI.parse('https://beta.quicklisp.org/quicklisp.lisp')
  response = Net::HTTP.get_response(url)
  temp_file = Tempfile.new(['quicklisp_commands', '.lisp'])

  File.open('quicklisp.lisp', 'wb') do |file|
    file.write(response.body)
  end
  commands = "(quicklisp-quickstart:install)\n(quicklisp:add-to-init-file)"
  temp_file.write(commands)
  temp_file.rewind


  system("sbcl --noinform --load quicklisp.lisp --script #{temp_file.path} --eval '(delete-file \"#{temp_file.path}\")'")

  # Clean up the temporary file
  temp_file.close
  temp_file.unlink
end

def clone_stumpwm_contrib

  repository_path = "home/.stumpwm.d/src/stumpwm-contrib"

  # Ensure the parent directory exists
  parent_directory = File.dirname(repository_path)
  FileUtils.mkdir_p(parent_directory)

  # Clone the repository
  system("git", "clone", "https://github.com/stumpwm/stumpwm-contrib", repository_path)

  puts "Modules cloned successfully into #{repository_path}"
end

def install_st
  http = Net::HTTP.new('dl.suckless.org')
  req = Net::HTTP::Get.new('/st/st-0.9.2.tar.gz')
  response = http.request(req)

tarball_path = 'st-0.9.2.tar.gz'
extract_path = File.expand_path('suckless')
source_dir = File.join(extract_path, 'st-0.9.2')
patches_dir = File.expand_path('suckless/st-0.9.2/patches')

File.open(tarball_path, 'wb') { |f| f.write(response.body) }
puts "File downloaded successfully"

# Extract the tarball
Zlib::GzipReader.open(tarball_path) do |gz|
  Gem::Package::TarReader.new(gz) do |tar|
    tar.each do |entry|
      dest = File.join(extract_path, entry.full_name)
      if entry.directory?
        FileUtils.mkdir_p(dest)
      else
        FileUtils.mkdir_p(File.dirname(dest))
        File.open(dest, "wb") { |f| f.write(entry.read) }
      end
    end
  end
end
puts "Tarball extracted"

File.delete(tarball_path)
puts "Tarball removed"

puts "Copying #{extract_path}/st/config.h to #{source_dir}/config.h"
FileUtils.cp("#{extract_path}/st/config.h","#{source_dir}/config.h")
puts "config.h copied successfully"

patch_urls = [
  'https://st.suckless.org/patches/scrollback/st-scrollback-ringbuffer-0.9.2.diff',
  'https://st.suckless.org/patches/clipboard/st-clipboard-0.8.3.diff'
]

FileUtils.mkdir_p(patches_dir)
patch_urls.each do |url|
  uri = URI(url)
  patch_content = Net::HTTP.get(uri)
  patch_filename = File.basename(uri.path)
  patch_path =  "#{patches_dir}/#{patch_filename}"

  File.open(patch_path, 'w') { |f| f.write(patch_content) }
  puts "Downloaded patch: #{patch_filename}"
  puts "Saved to: #{File.expand_path(patch_path)}"

Dir.chdir(source_dir) do
  puts Dir.pwd
  patch_command = "patch -p1 < #{File.expand_path(patch_path)}"
  stdout, stderr, status = Open3.capture3(patch_command)
  if status.success?
    puts "Successfully applied patch: #{patch_filename}"
  else
    puts "Failed to apply patch: #{patch_filename}"
    puts "Error: #{stderr}"
  end
end
end

puts "All patches applied"

make_command = "make -C #{source_dir}"
system(make_command)

# Run make install with privilege escalation
install_command = "#{$privilege_escalator} make -C #{source_dir} install"

puts "Running: #{install_command}"
system(install_command)

if $?.success?
  puts "Installation completed successfully"
else
  puts "Installation failed with exit code: #{$?.exitstatus}"
end
end

def clone_fzf_mksh
  repository_path = "home/.fzf-mksh"

  # Ensure the parent directory exists
  parent_directory = File.dirname(repository_path)
  FileUtils.mkdir_p(parent_directory)

  # Clone the repository
  system("git", "clone", "https://github.com/seankhl/fzf-mksh", repository_path)

  puts "fzf-mksh cloned into #{repository_path}"
end

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: dont do this directly but ruby setup.rb [options]]"

  opts.on("-a", "--all", "Run all actions") do
    options[:all] = true
  end

  opts.on("-s", "--stump-contrib", "Clone stumpwm-contrib") do
    options[:stump_contrib] = true
  end
  opts.on("-m", "--fzf-mksh", "Clone stumpwm-contrib") do
    options[:clone_fzf_mksh] = true
  end

  opts.on("-q", "--quicklisp", "Install Quicklisp") do
    options[:quicklisp] = true
  end

  opts.on("-t", "--st", "Install ST terminal") do
    options[:st] = true
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

if options[:all]
  install_quicklisp
  clone_stumpwm_contrib
  install_st
  clone_fzf_mksh
else
  install_quicklisp if options[:quicklisp]
  clone_stumpwm_contrib if options[:stump_contrib]
  install_st if options[:st]
  clone_fzf_mksh if options[:clone_fzf_mksh]
end
