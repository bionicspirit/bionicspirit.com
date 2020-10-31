---
title: "Organize and Index Your Screenshots (OCR) on macOS"
date: 2020-10-30 16:57:40+0200
description: Screenshots contain text, text that should be searchable, as finding a screenshot later is the whole point of creating it.
---

I maintain a growing `Screenshots` folder. Screenshots contain text, text that should be searchable, as finding a screenshot later is the whole point of creating it.

My folder is stored in Dropbox, and unfortunately they are not indexing images on the "Plus" plan, at the moment of writing. And OneDrive currently has this functionality suspended for personal accounts, due to some technical issues they are having. Having to depend on a cloud service for searching your screenshots sucks, and I don't want the lock-in.

Here's how to organize and index your screenshots locally, using open source stuff ...

## Tesseract OCR Engine

[Tesseract OCR](https://github.com/tesseract-ocr/tesseract) is a neat OSS project, available in Homebrew:

```sh
brew install tesseract
```

Given a PNG image file, you can convert it into a properly annotated PDF with:

```sh
tesseract /input/path/to/file.png /output/path/to/file -l eng pdf
```

This will process `/input/path/to/file.png` and create a properly annotated `/output/path/to/file.pdf` from it, that can then be indexed by macOS's Spotlight, or Dropbox.

## Folder organization

In Dropbox I have the following directory structure:

- Screenshots
  - Processing
  - Raw
  - OCR

`Screenshots/Processing`

I'm using this script that can take images from one directory and 

```ruby
#!/usr/bin/env ruby

require 'optparse'
require 'pp'

USAGE = <<ENDUSAGE
Usage:
  screenshots-sync [-h] -i <path> -o <path> -r <path> [-d]
ENDUSAGE

options = {}
OptionParser.new do |opts|
  opts.banner = USAGE
  
  opts.on("-i", "--input-dir INPUT_DIR", "Path to the processing directory.") {|v| 
    raise OptionParser::InvalidArgument unless File.directory?(v)
    options[:processingDir] = File.expand_path(v)
  }
  opts.on("-o", "--output-ocr-dir OUTPUT_OCR_DIR", "Path to the output directory for OCR-ed PDF files.") {|v| 
    raise OptionParser::InvalidArgument unless File.directory?(v)
    options[:ocrDir] = File.expand_path(v)
  }
  opts.on("-r", "--output-raw-dir OUTPUT_RAW_DIR", "Path to the output directory for the raw PNG files.") {|v| 
    raise OptionParser::InvalidArgument unless File.directory?(v)
    options[:rawDir] = File.expand_path(v)
  }
  opts.on("-f", "--filter FILTER", "File name filter, defaults to *.png") {|v| 
    options[:filter] = v
  }
  opts.on("-v", "--[no-]verbose", "Run verbosely") {|v| 
    options[:verbose] = v
  }
end.parse!

options[:tesseract] = `which tesseract`
options[:tesseract] = "/usr/local/bin/tesseract" unless File.exists? options[:tesseract]
raise "Missing tesseract executable from PATH" unless File.executable?(options[:tesseract])

options[:filter] = "*.png" unless options[:filter]

raise OptionParser::MissingArgument.new("--input-dir") if options[:processingDir].nil?
raise OptionParser::MissingArgument.new("--output-ocr-dir") if options[:ocrDir].nil?
raise OptionParser::MissingArgument.new("--output-raw-dir") if options[:rawDir].nil?

if options[:verbose]
  puts "\nRunning with options:\n\n" 
  pp options
  puts
end

def execute(cmd, options)
  puts cmd if options[:verbose]
  out = if options[:verbose] then "" else "1>/dev/null 2>&1" end
  r = system("#{cmd} #{out}")
  unless r
    $stderr.puts "ERROR — command exited with error code (#{r}):\n  #{cmd}"
    exit 1
  end
end

Dir["#{options[:processingDir]}/#{options[:filter]}"].each do |f|
  source = File.expand_path(f)

  if f =~ /(\d{4}-\d{2}-\d{2})\s+at\s+(\d{2}\.\d{2}\.\d{2})/
    raw_output = File.join(options[:rawDir], "Screenshot #{$1} #{$2}#{File.extname(f)}")
    ocr_output = File.join(options[:ocrDir], "Screenshot #{$1} #{$2}#{File.extname(f)}")
  else
    raw_output = File.join(options[:rawDir], File.basename(f))
    ocr_output = File.join(options[:ocrDir], File.basename(f))
  end

  if source != raw_output
    execute("mv \"#{source}\" \"#{raw_output}\"", options)
  end

  execute("#{options[:tesseract]} \"#{raw_output}\" \"#{ocr_output}\" -l eng pdf", options)
end

```



```sh
defaults write com.apple.screencapture location ~/Dropbox/Screenshots/Processing
```