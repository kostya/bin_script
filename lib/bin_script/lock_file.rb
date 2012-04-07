# -*- encoding: utf-8 -*-
class LockFile
  attr_accessor :logger, :path, :quiet

  # By default print errors
  @quiet = false

  def initialize(path, logger = nil)
    if path == nil
      raise "file path cannot be nil"
    end
    @path = path
    @logger = logger || $logger
  end

  def lock(waiting_unlock = false)
    flags = File::WRONLY | File::TRUNC | File::CREAT

    @f = File.open(@path, flags)
    flags = File::LOCK_EX
    flags |= File::LOCK_NB if waiting_unlock == false

    unless @f.flock flags
      log "File '#{@path}' already open in exclusive mode.\n"
      return true
    end
    return false
  end

  def unlock
    @f.close
    File.delete( @f.path)
  rescue Errno::ENOENT
    #do nothing
  end

  def log(str)
    return if @quiet
    if @logger
      @logger.warn str
    else
      print str
    end
  end
end