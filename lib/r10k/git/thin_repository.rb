require 'r10k/git'
require 'r10k/git/working_repository'

class R10K::Git::ThinRepository < R10K::Git::WorkingRepository

  def initialize(basedir, dirname)
    super

    if exist?
      set_cache(origin)
    end
  end

  def clone(remote, opts = {})
    # todo check if opts[:reference] is set
    set_cache(remote)
    @cache_repo.sync

    super(remote, opts.merge(:reference => @cache_repo.git_dir))
    setup_cache_remote
  end

  def fetch(remote = 'cache')
    git ['fetch', remote], :path => @path.to_s
  end

  def cache
    git(['config', '--get', 'remote.cache.url'], :path => @path.to_s).stdout
  end

  private

  def set_cache(remote)
    @cache_repo = R10K::Git::Cache.generate(remote)
  end

  def setup_cache_remote
    git ["remote", "add", "cache", @cache_repo.git_dir], :path => @path.to_s
    fetch
  end
end
