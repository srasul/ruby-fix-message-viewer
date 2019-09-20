# FixSpecFileLocator.rb
# Wed 16 Sept 2009
#
# This file contains the paths to the various FIX Specification xml
# files

require 'pp'
require 'logger'

class FixSpecFileLocator
  def initialize(baseDir)

    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO

    @fixSpecFiles = {}
    @log.debug("base dir: " + baseDir)
    Dir.glob(baseDir+"/fixspec/*.xml") do |filename|
      filePath = File.new(filename, "r").path
      @log.debug("fikePath "+ filePath)
      @fixSpecFiles[File.basename(filename).delete(".xml")] = filename
    end
  end

  def getFixSpecFile(fixSpec)
    @log.debug("getting spec file for: " + fixSpec.delete("."))
    @log.debug("fix spec for " + fixSpec + " is " + @fixSpecFiles[fixSpec.delete(".")].to_s)
    @fixSpecFiles[fixSpec.delete(".")]
  end
end

#FixSpecFileLocator.new(File.dirname($0))
