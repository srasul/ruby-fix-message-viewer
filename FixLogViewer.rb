#! /usr/bin/env ruby
# FixLogViewer.rb
# July 11, 2007
#

require 'rubygems'
require 'logger'
require 'optparse'
require 'pp'
require ENV["FLV_HOME"]+"/ReadFIXFieldSpec.rb"

begin
  require 'term/ansicolor'
  include Term::ANSIColor
rescue LoadError
  require ENV["FLV_HOME"]+"/fakecolor.rb"
end


class FixLogViewer
  def initialize(fixLogFileName, options)
    @allFixFields = nil
    @colorOutput = options[:color]
    @evenOdd = "even"
    if(options[:grep_to_apply] != nil)
      @grep_to_apply = options[:grep_to_apply]
    else
      # TODO
    end
    @log = Logger.new(STDOUT)
    if(options[:verbose] == true)
      @log.level = Logger::DEBUG
    else
      @log.level = Logger::INFO
    end

    @log.debug("set colorOutput to " + @colorOutput.to_s)

    if "-" == fixLogFileName
      @log.info("will read from stdinput!")
      ARGF.each{ |line| processLine(line)}
    elsif fixLogFileName == nil || !File.exists?(fixLogFileName)
      if(fixLogFileName == nil)
        @log.error "No Fix Log file given! use the --help option to see how to use this script"
      else
        @log.error fixLogFileName + " does not exist!"
      end
      exit!
    elsif File.exists?(fixLogFileName)
      File.open(fixLogFileName, "r").each{ |line| processLine(line)}
    end
  end

  private

  def printInYellow(someText)
    if(@colorOutput == true)
      yellow(someText).reset
    else
      someText
    end
  end

  def printInRed(someText)
    if(@colorOutput == true)
      red(someText).reset
    else
      someText
    end
  end

  def printLine(lineToPrint)
    if(@colorOutput == true)
      if (@evenOdd == "even")
        puts green(lineToPrint).reset
        @evenOdd = "odd"
      else
        puts lineToPrint
        @evenOdd = "even"
      end
    else
      puts lineToPrint
    end
  end

  def processLine(theLine)
    # where the FIX message starts
    start = theLine.index("8=FIX")
    if(start == nil)
      @log.warn("The line: '" + theLine.chomp + "' does not start with 8=FIX")
      #exit 1
      return
    end
    # where the FIX message ends
    endIndex = theLine.rindex("\x01")
    if(endIndex == nil)
      @log.warn("The line: '" + theLine.chomp + "' does not end with an 0x01 (asci zero)")
      #exit 1
      return
    end

    theLine = theLine[start, endIndex]
    allFieldInMessage = theLine.split("\x01")

    if(@allFixFields == nil)
      # need to know what version FIX we are so that
      # we get the right field names for the field numbers
      fixVersion = allFieldInMessage[0].split("=")[1];
      @log.info("got fix version " + fixVersion)
      @allFixFields = AllFixFields.new(fixVersion)
      
    end
    
    puts printInYellow("        =-=-=-=-=-=-==-=-=-=-=-=-==-=-=-=-=-=-=        ")

    @log.debug( "allFieldsInMessage.length: " + allFieldInMessage.length.to_s)
    @log.debug( allFieldInMessage)
    for index in (0..allFieldInMessage.length)
      if(allFieldInMessage[index] != nil)
        aFieldAndValue = allFieldInMessage[index].strip;
        if(aFieldAndValue != nil && aFieldAndValue.length > 0)
          @log.debug("processing index:" + index.to_s)
          @log.debug(aFieldAndValue)
          @log.debug(aFieldAndValue.length.to_s)
          fieldNameAndValue = aFieldAndValue.split("=")
          if(fieldNameAndValue.length > 1)
            @log.debug("fieldNameAndValue.length is > 1")
            @log.debug(fieldNameAndValue.length.to_s)
            fieldName = @allFixFields.getFieldName(fieldNameAndValue[0])
            @log.debug("field name: " + fieldName.to_s)
            if(fieldName == nil) # looks like a custom field
              fieldName = fieldNameAndValue[0]
            end
            lineToPrint = nil
            padding = @allFixFields.getLongestFieldLength() - fieldName.length - 2
            @log.debug("padding: " + padding.to_s)
            if(fieldNameAndValue[0] == "35")
              lineToPrint = fieldName +
                "  =  ".rjust(padding) + printInRed(@allFixFields.getMessageType(fieldNameAndValue[1]))  +
                printInRed("  ".rjust(30 - @allFixFields.getMessageType(fieldNameAndValue[1]).length) + allFieldInMessage[index])
            else
              lineToPrint = fieldName + "  =  ".rjust(padding) + fieldNameAndValue[1] +
                "  ".rjust(30 - fieldNameAndValue[1].to_s.length) + allFieldInMessage[index]
            end
            printLine(lineToPrint)
          end
        end
      end
    end
  end
end

options={}

#default options
options[:color]=false
#options[:grep_to_apply]=nil
options[:verbose]=false

optparse = OptionParser.new do |opts|
  
  opts.banner = "Usage: FixLogViewer.rb [options] [fixlogfile]"
  
  opts.on('--color', '-c', 'Generate color output') do
    options[:color] = true
  end

  # TODO
  #opts.on('--grep', '-g', 'Grep the fix logs for this (eg 35=8)') do |grep_to_apply|
  #  options[:grep_to_apply] = grep_to_apply
  #end

  opts.on('--verbose', '-v', 'Generate verbose debug output (useful for reporting/debugging errors)') do
    options[:verbose]=true
  end
  
  opts.on('--help', '-h', 'Display help message') do
    puts opts
    puts "if fixlogfile is - then read fix logs from STDIN"
    exit
  end
  
end

optparse.parse!

FixLogViewer.new(ARGV[0], options)