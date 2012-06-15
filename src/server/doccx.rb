#    Folder Index Generator

require 'set'
require 'grit'
require 'optparse'
require 'fileutils'

# ## Parsing Arguments
#
# Following arguments are mandatory:
#
#   * `working`: specify **working** directory.
#   * `sources`: specify **sources** directory.
options = {}
option_parser = OptionParser.new { |opts|
  opts.on ("--working DIR") { |dir| options[:working] = dir }
  opts.on ("--sources DIR") { |dir| options[:sources] = dir }
}.parse!

# ## Get Touched Directories Recursively
#
# Touched directories are directories of all touched and deleted files, and
# their ancestor directories, up to the root directory of the repository.
directories = Set.new
File.new("#{options[:working]}/.touched").each_line { |file| directories.add File.dirname file }
File.new("#{options[:working]}/.deleted").each_line { |file| directories.add File.dirname file }
tmp_set_0 = directories
while tmp_set_0.length > 1 or !tmp_set_0.include? '.'
  tmp_set_1 = Set.new
  tmp_set_0.each { |directory| tmp_set_1.add File.dirname directory }
  directories |= tmp_set_0 = tmp_set_1
end

# ## Human Readable File Size
#
# Borrowed from [枕を欹てて聴く]'s blog.
#
# [枕を欹てて聴く]: http://d.hatena.ne.jp/Constellation/20090424/1240570837
@bytes = %w(B K M G T P E Z Y)
def humanize_number size
  cnt = 0
  loop do
    break if size < 1024 && cnt < 8
    size /= 1024.0
    cnt += 1
  end
  if 0 < size && size < 10
    sprintf("%.1f%s", size, @bytes[cnt])
  else
    sprintf("%i%s", size, @bytes[cnt])
  end
end

# ## Generate docas.idx For Touched Directories
#
# Find all repositories
#
# Grit is used to get latest commit message for each file. Grit use
# `posix_spawn` and `git` command to get commit logs internally.
#
# In order to accelerate processing, multi-threading is used to make Grit's
# `log` faster. The maximum parallel threads is set to 4.
#
# Generated `docas.idx` will be of the following format:
#
#   * type
#   * name
#   * action
#   * size
#   * sloc
#   * author
#   * email
#   * date
#   * description
#   * message
#
# Fields are seperated by ` | ` (vertical bar with left and right spaces). Each
# line represents a single entry.
repo = Grit::Repo.new options[:sources]
gitmodules = Grit::Submodule.config repo
directories.each do |directory|
  FileUtils.mkdir_p target_directory = "#{options[:working]}/ghpages/#{directory}"
  open("#{target_directory}/docas.idx", 'w') { |f|
    threads = []
    Dir.glob("#{directory}/*").each { |glob|
      if threads.size == 4
        threads.map(&:join)
        threads.clear
      end
      threads.push Thread.new {
        file = File.open glob
        log = repo.log('master', glob, :max_count =>1)[0]
        type = file.stat.directory? ? 'd' : 'f'
	type = 'm' + gitmodules[glob]["url"].match(/git(?:@|:\/\/)github\.com(?::|\/)([^\.]*)(\.git)?/)[1] if (type == 'd') && (gitmodules.include? glob)
        size = file.size
        sloc = ''
        puts glob
        author = log.author.name.gsub '|', '||'
        email = log.author.email.gsub '|', '||'
        date = log.date.strftime '%s'
        message = log.message.gsub '|', '||'
        filename = glob[directory.size+1...glob.size]
        desc = ''
        if (type == 'd')
          action = ''
          size = "#{Dir.new(glob).entries.size - 2} items"
        else
          size = humanize_number size
          segments = filename.split '.'
          while segments[0] == ''
            segments.shift
          end
          documentname = segments[0...(segments.size > 1 ? segments.size - 1 : segments.size)].join('.') + '.html'
          document = "#{options[:working]}/ghpages/#{directory}/#{documentname}"
          if (type == 'f') && (File.exists? document)
            sloc = 0
            file.each_line { |line| sloc += 1 unless /\S/ !~ line.encode!('UTF-8', 'UTF-8', :invalid => :replace) }
            action = 's'
	    begin
              source = File.open document
              first_line = source.readline.strip

              # Markdown files' descriptions are the `code` tags at
              # first lines. Remove the `<pre><code>` parts from the string.
	      if first_line != '<!DOCTYPE html>'
                puts document, 'MARKDOWN'
                description = first_line[11..-1]

              # Regular sources' descriptions are the `code` comment
              # at first lines.
	      else
                source.readline
	        description = source.readline.strip
	        description = (description[2..-1] || '').gsub '|', '||'
	      end
	    rescue
	    end
          else
            action = 'g'
          end
        end
        f << "#{type} | #{filename} | #{action} | #{size} | #{sloc} | #{author} | #{email} | #{date} | #{description} | #{message}\n"
      }
    }
    threads.map(&:join)
  }
end
