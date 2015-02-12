require 'r10k/git'
require 'r10k/git/base_repository'
require 'r10k/git/alternates'

class R10K::Git::WorkingRepository < R10K::Git::BaseRepository

  attr_reader :path

  def git_dir
    @path + '.git'
  end

  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  def clone(remote, opts = {})
    argv = ['clone', remote, @path.to_s]
    if opts[:reference]
      argv += ['--reference', opts[:reference]]
    end
    git argv

    if opts[:ref]
      checkout(opts[:ref])
    end
  end

  def checkout(ref)
    git ['checkout', ref], :path => @path.to_s
  end

  def fetch
    git ['fetch'], :path => @path.to_s
  end

  def exist?
    @path.exist?
  end

  def head
    git(['rev-parse', 'HEAD'], :path => @path.to_s).stdout
  end

  def alternates
    R10K::Git::Alternates.new(git_dir)
  end

  def origin
    result = git(['config', '--get', 'remote.origin.url'], :path => @path.to_s, :raise_on_fail => false)
    if result.success?
      result.stdout
    end
  end
end
