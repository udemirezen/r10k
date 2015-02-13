require 'r10k/git/thin_repository'

class R10K::Git::StatefulRepository

  # Create a new shallow git working directory
  #
  # @param ref     [String, R10K::Git::Ref]
  # @param remote  [String]
  # @param basedir [String]
  # @param dirname [String]
  def initialize(ref, remote, basedir, dirname)
    @ref = ref
    @remote = remote

    @repo = R10K::Git::ThinRepository.new(basedir, dirname)
    @cache = R10K::Git::Cache.generate(remote)
  end

  def sync
    @cache.sync

    sha = @cache.__resolve(@ref)

    case status
    when :absent
      @repo.clone(@remote, {:ref => sha})
    when :mismatched
      @repo.path.rmtree
      @repo.clone(@remote, {:ref=> sha})
    when :outdated
      @repo.fetch
      @repo.checkout(sha)
    end
  end

  def status
    if !@repo.exist?
      :absent
    elsif !@repo.git_dir.exist?
      :mismatched
    elsif !(@repo.origin == @remote)
      :mismatched
    elsif !(@repo.head == @cache.__resolve(@ref))
      :outdated
    else
      :insync
    end
  end
end
