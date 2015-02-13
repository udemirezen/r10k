require 'r10k/git'
require 'r10k/git/repository'

# ref: A 40-byte hex representation of a SHA1 or a name that denotes a
# particular object. They may be stored in a file under $GIT_DIR/refs/
# directory, or in the $GIT_DIR/packed-refs file.
#
# @see https://www.kernel.org/pub/software/scm/git/docs/gitglossary.html
# @api private
class R10K::Git::Ref

  # @!attribute [r] ref
  #   @return [String] The git reference
  attr_reader :ref

  # @!attribute [rw] repository
  #   @return [R10K::Git::Repository] A git repository that can be used to
  #     resolve the git reference to a commit.
  attr_accessor :repository

  def initialize(ref, repository = nil)
    @ref        = ref
    @repository = repository
    @_ref_type  = :unknown
  end

  # Can we locate the commit in the related repository?
  def resolvable?
    sha1
    true
  rescue R10K::Git::UnresolvableRefError
    false
  end

  def fetch?
    FETCH_METHOD[ref_type].call
  end

  def sha1
    if @repository.nil?
      raise ArgumentError, "Cannot resolve #{self.inspect}: no associated git repository"
    else
      @repository.rev_parse(ref)
    end
  end

  def ==(other)
    other.is_a?(R10K::Git::Ref) && other.sha1 == self.sha1
  rescue ArgumentError, R10K::Git::UnresolvableRefError
    false
  end

  def to_s
    ref
  end

  def inspect
    "#<#{self.class}: #{to_s} (#{@_ref_type})>"
  end

  def ref_type
    if @_ref_type == :unknown
      @_ref_type = @repository.__ref_type(ref)
    end
    @_ref_type
  end

  FETCH_METHOD = {
    :branch => { :fetch? => proc { true } },
    :tag    => { :fetch? => proc { resolvable? }},
    :commit => { :fetch? => proc { resolvable? }},
  }
end
