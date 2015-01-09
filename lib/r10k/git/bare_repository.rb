require 'r10k/git'
require 'r10k/git/base_repository'
require 'r10k/logging'

class R10K::Git::BareRepository < R10K::Git::BaseRepository

  def git_dir
    @path
  end

  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  def clone(remote)
    git ['clone', '--mirror', remote, git_dir.to_s]
  end

  def fetch
    git ['fetch', '--prune'], :git_dir => git_dir.to_s
  end

  def exist?
    @path.exist?
  end

  def __ref_type(pattern)
    if branches.include? pattern
      :branch
    elsif tags.include? pattern
      :tag
    elsif __resolve(pattern)
      :commit
    else
      :unknown
    end
  end

  def get_ref(pattern)
    R10K::Git::Ref.new(pattern, self)
  end
end
