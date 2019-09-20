#!/usr/bin/env ruby
#

require 'rexml/document'
require 'rexml/streamlistener'

require ENV["FLV_HOME"]+"/FixSpecFileLocator"

# class to read the names and number of all the fields
# from the QuickfixJ XML config file
class FieldListener
  include REXML::StreamListener

  attr(:allFields, true)
  attr(:messageTypes, true)
  
  def tag_start(name, attrs)
    if(name == "field" && attrs["number"] != nil && attrs["name"] != nil)
      #puts "got field: " + attrs["name"] + " with number " + attrs["number"]
      @allFields[attrs["number"]] = attrs["name"]
      if(@allFields["longestNameLength"] == nil)
        @allFields["longestNameLength"] = attrs["name"].length
      else
        if(attrs["name"].length > @allFields["longestNameLength"])
          @allFields["longestNameLength"] = attrs["name"].length
        end
      end
    end

    if(name == "message" && attrs["name"] != nil && attrs["msgtype"] != nil && attrs["msgcat"] != nil)
        @messageTypes[attrs["msgtype"]] = attrs["name"]
    end
  end
end

class AllFixFields

  def initialize(tag8)

    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO

    @allFields = {}
    @messageTypes = {}

    #quickFixJFile = AllQuickfixFIXFiles.new.localFixPaths[tag8]
    quickFixJFile = FixSpecFileLocator.new(ENV["FLV_HOME"]).getFixSpecFile(tag8)
    @log.debug("quickFixJFile: " + quickFixJFile)
    fieldsListener = FieldListener.new
    fieldsListener.allFields = @allFields
    fieldsListener.messageTypes = @messageTypes
    
    REXML::Document.parse_stream(File.new(quickFixJFile.strip, "r"), fieldsListener)
  end

  def getFieldName(fieldNumber)
    @allFields[fieldNumber.to_s]
  end

  def getMessageType(tag35)
    @messageTypes[tag35.to_s]
  end

  def getLongestFieldLength()
     @allFields["longestNameLength"]
  end
  

end

#test = AllFixFields.new("FIX.4.2")
#puts "field number 7 has name: " + test.getFieldName(7)

#test2 = AllQuickfixFIXFiles.new
