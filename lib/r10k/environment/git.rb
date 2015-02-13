require 'r10k/logging'
require 'r10k/puppetfile'
require 'r10k/git/working_dir'
require 'r10k/git/stateful_repository'

# This class implements an environment based on a Git branch.
#
# @since 1.3.0
class R10K::Environment::Git < R10K::Environment::Base

  include R10K::Logging

  # @!attribute [r] remote
  #   @return [String] The URL to the remote git repository
  attr_reader :remote

  # @!attribute [r] ref
  #   @return [String] The git reference to use for this environment
  attr_reader :ref

  # @!attribute [r] working_dir
  #   @api private
  #   @return [R10K::Git::WorkingDir] The git working directory backing this environment
  attr_reader :working_dir

  # Initialize the given SVN environment.
  #
  # @param name [String] The unique name describing this environment.
  # @param basedir [String] The base directory where this environment will be created.
  # @param dirname [String] The directory name for this environment.
  # @param options [Hash] An additional set of options for this environment.
  #
  # @param options [String] :remote The URL to the remote git repository
  # @param options [String] :ref The git reference to use for this environment
  def initialize(name, basedir, dirname, options = {})
    super
    @remote = options[:remote]
    @ref    = options[:ref]

    #@working_dir = R10K::Git::WorkingDir.new(@ref, @remote, @basedir, @dirname)
    @working_dir = R10K::Git::StatefulRepository.new(@ref, @remote, @basedir, @dirname)
  end

  # Clone or update the given Git environment.
  #
  # If the environment is being created for the first time, it will
  # automatically update all modules to ensure that the environment is complete.
  #
  # @api public
  # @return [void]
  def sync
    @working_dir.sync
    @synced = true
  end

  def status
    return @working_dir.status
    if !@working_dir.exist?
      :absent
    elsif !@working_dir.git?
      :mismatched
    elsif !(@remote == @working_dir.remote)
      :mismatched
    elsif !@synced
      :outdated
    else
      :insync
    end
  end

  # @deprecated
  # @api private
  def sync_modules
    modules.each do |mod|
      logger.debug "Deploying module #{mod.name}"
      mod.sync
    end
  end
end
