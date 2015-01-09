require 'r10k/git'
require 'r10k/logging'
require 'r10k/git/alternates'

class R10K::Git::WorkingRepository

  attr_reader :path

  def git_dir
    @path + '.git'
  end

  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  def clone(remote, opts = {})
    argv = ['clone', remote, @path.to_s]
    if opts[:ref]
      argv += ['-b', opts[:ref]]
    end
    if opts[:reference]
      argv += ['--reference', opts[:reference]]
    end
    git argv
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
    git(['config', '--get', 'remote.origin.url'], :path => @path.to_s).stdout
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
