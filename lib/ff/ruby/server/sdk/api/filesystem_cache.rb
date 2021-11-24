require "libcache"

class FilesystemCache < FileCache

  def get_keys

    @keys
  end
end