# Generate `docas.index` for all touched source directories.

require 'optparse'
require 'set'
require 'grit'
require 'fileutils'

options = {}
option_parser = OptionParser.new do |opts|
  opts.on("--working_dir DIR") do |dir|
    options[:working_dir] = dir
  end
  opts.on("--sources_dir DIR") do |dir|
    options[:sources_dir] = dir
  end
end
option_parser.parse!

directories = Set.new
STDIN.lines { |directory| directories.add File.dirname directory }
tmp_set_0 = directories
while tmp_set_0.length > 1 or !tmp_set_0.include? '.'
  tmp_set_1 = Set.new
  tmp_set_0.each { |directory| tmp_set_1.add File.dirname directory }
  directories |= tmp_set_0 = tmp_set_1
end

repo = Grit::Repo.new options[:sources_dir]
# /"(d|-)","(.+)","([^"]+)","(.+)","(.+)","(.+)","<(.+)>","(0|1|2)","(\d+|-)"/
#
@bytes = %w(B K M G T P E Z Y)
def humanize_number3 size
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

directories.each do |directory|

  FileUtils.mkdir_p target_directory = "#{options[:working_dir]}/ghpages/docas/tree/#{directory}"

  open("#{target_directory}/docas.index", "w") { |f|

    threads = []

    Dir.glob("#{directory}/*").each do |glob|

      if threads.size == 4
        threads.map(&:join)
        threads.clear
      end

      threads.push Thread.new {

	file   = File.open glob
	log    = repo.log('master', glob, :max_count =>1)[0]

	type   = file.stat.directory? ? 'd' : 'f'
	size   = humanize_number3 file.size
	sloc   = 0
	author = log.author.name.gsub '|', '||'
	email  = log.author.email.gsub '|', '||'
	date   = log.date.strftime '%s'
	msg    = log.message.gsub '|', '||'
        filename = glob[directory.size+1...glob.size]
	desc   = ""
	if (type == 'd') && (Dir.exists? "#{options[:working_dir]}/ghpages/#{glob}")
	  action = 'd'
        else
	  segments = filename.split "."
	  documentname = segments[0...segments.size-1].join(".") + ".html"
	  if documentname == ".html"
	    documentname = filename + ".html"
	  end
	  document = "#{options[:working_dir]}/ghpages/#{directory}/#{documentname}"
	  puts "documents:" + document
	  if (type == 'f') && (File.exists? document)
	    file.each_line { |line| sloc += 1 unless /\S/ !~ line.encode!('UTF-8', 'UTF-8', :invalid => :replace) }
	    source = File.open document
	    source.readline
	    desc   = source.readline
	    desc   = (desc[2...desc.size] || "").strip.gsub '|', '||'
	    action = 's'
	  else
	    action = 'g'
	  end
	end

	f << "#{type} | #{filename} | #{action} | #{size} | #{sloc} | #{author} | #{email} | #{date} | #{desc} | #{msg}\n"

    }

    end

    threads.map(&:join)

  }

end
