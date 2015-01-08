require 'r10k/git'
require 'r10k/logging'

class R10K::Git::BareRepository

  def git_dir
    @path.to_s
  end

  def initialize(remote, basedir, dirname)
    @remote = remote
    @path   = Pathname.new(File.join(basedir, dirname))
  end

  def clone
    git ['clone', '--mirror', @remote, git_dir]
  end

  def fetch
    git ['fetch', '--prune'], :git_dir => git_dir
  end

  def exist?
    @path.exist?
  end

  def branches
    output = git %w[for-each-ref refs/heads --format %(refname)], :git_dir => git_dir
    output.stdout.scan(%r[refs/heads/(.*)$]).flatten
  end

  def tags
    output = git %w[for-each-ref refs/tags --format %(refname)], :git_dir => git_dir
    output.stdout.scan(%r[refs/tags/(.*)$]).flatten
  end

  def __resolve(pattern)
    result = git ['rev-parse', "#{pattern}^{commit}"], :git_dir => git_dir, :raise_on_fail => false
    if result.success?
      result.stdout
    end
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

  include R10K::Logging

  private

  # Wrap git commands
  #
  # @param cmd [Array<String>] cmd The arguments for the git prompt
  # @param opts [Hash] opts
  #
  # @option opts [String] :path
  # @option opts [String] :git_dir
  # @option opts [String] :work_tree
  # @option opts [String] :raise_on_fail
  #
  # @raise [R10K::ExecutionFailure] If the executed command exited with a
  #   nonzero exit code.
  #
  # @return [String] The git command output
  def git(cmd, opts = {})
    raise_on_fail = opts.fetch(:raise_on_fail, true)

    argv = %w{git}

    if opts[:path]
      argv << "--git-dir"   << File.join(opts[:path], '.git')
      argv << "--work-tree" << opts[:path]
    else
      if opts[:git_dir]
        argv << "--git-dir" << opts[:git_dir]
      end
      if opts[:work_tree]
        argv << "--work-tree" << opts[:work_tree]
      end
    end

    argv.concat(cmd)

    subproc = R10K::Util::Subprocess.new(argv)
    subproc.raise_on_fail = raise_on_fail
    subproc.logger = self.logger

    result = subproc.execute

    result
  end
end
