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

# ## Get Document Name
#
# Document name will be the same file name with extention `.html`, examples:
#
#   + `awe_some_source.rb` -> `aws_some_source.html`
#   + `.hidden_source` -> `hidden_source.html`
def get_document_name source_name
  segments = source_name.split '.'
  while segments[0] == ''
    segments.shift
  end
  segments[0...(segments.size > 1 ? segments.size - 1 : 1)].join('.') + '.html'
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
submodules = Grit::Submodule.config repo

directories.each do |directory|
  FileUtils.mkdir_p target_directory = "#{options[:working]}/ghpages/#{directory}"
  File.open "#{target_directory}/docas.idx", 'w' do |f|
    threads = []
    Dir.glob("#{directory}/*").each do |glob|
      if threads.size == 4
        threads.map(&:join)
        threads.clear
      end
      threads.push Thread.new {
        file = File.open glob
        type = file.stat.directory? ? 'd' : 'f'
	type = 'm' + submodules[glob]["url"].match(/(?:git@|git:\/\/|http:\/\/)github\.com(?::|\/)([^\.]*)(\.git)?/)[1] if (type == 'd') && (submodules.include? glob)
        name = glob[directory.size + 1...glob.size]
        action = ''
        size = file.size
        sloc = ''
        log = repo.log('master', glob, :max_count =>1)[0]
        author = log.author.name.gsub '|', '||'
        email = log.author.email.gsub '|', '||'
        date = log.date.strftime '%s'
        description = ''
        message = log.message.gsub '|', '||'

        # Folder specific fields.
        if type == 'd'
          size = "#{Dir.new(glob).entries.size - 2} items"
          readme_path = "#{glob}/README.md"
          if File.exists? readme_path
            begin
              readme = File.open readme_path
              description_line = readme.readline
              if readme.eof? or readme.readline.strip.size == 0
                description = description_line.match(/\s{4}(.*)/)[1]
              end
            rescue
            end
          end

        # Populating file specified fields.
        else

          size = humanize_number size
          document = "#{options[:working]}/ghpages/#{directory}/#{get_document_name name}"
          puts document
          if (type == 'f') && (File.exists? document)
            sloc = 0
            file.each_line { |line| sloc += 1 unless /\S/ !~ line.encode!('UTF-8', 'UTF-8', :invalid => :replace) }
            action = 's'
          else
            action = 'g'
          end

          # Recognize description for the source file.
          begin
            source = File.open glob
            description_line = source.readline
            if description_line[0..1] == '#!'
              source.readline
              description_line = source.readline 
            end
            puts description_line
            if source.eof? or source.readline.strip.size <= 1
              description = description_line.match(/\S{1,3}\s{4}(.*)/)[1]
            end
          rescue
          end

        end

        f.puts [
          type,
          name,
          action,
          size,
          sloc,
          author,
          email,
          date,
          description,
          message
        ].join ' | '

      }
    end
    threads.map(&:join)
  end
end
