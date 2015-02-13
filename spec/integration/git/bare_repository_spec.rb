require 'spec_helper'
require 'r10k/git/bare_repository'

require 'tmpdir'

describe R10K::Git::BareRepository do

  include_context 'Git integration'

  let(:remote) { File.join(remote_path, 'puppet-boolean.git') }
  let(:basedir) { Dir.mktmpdir }
  let(:dirname) { 'bare-repo.git' }

  after do
    FileUtils.remove_entry_secure(basedir)
  end

  subject { described_class.new(basedir, dirname) }

  it_behaves_like 'a git repository'

  describe "checking for the presence of the repo" do
    it "exists if the repo is present" do
      subject.clone(remote)
      expect(subject.exist?).to be_truthy
    end

    it "doesn't exist if the repo is not present" do
      expect(subject.exist?).to be_falsey
    end
  end

  describe "cloning the repo" do
    it "creates the repo at the expected location" do
      subject.clone(remote)
      config = File.read(File.join(basedir, dirname, 'config'))
      expect(config).to match(remote)
    end

    # error case?
  end

  describe "updating the repo" do
    let(:objectdir) { objectdir = File.join(basedir, dirname, 'objects') }

    before do
      subject.clone(remote)
      # Remove objects to pretend the upstream made changes
      Dir.glob(File.join(objectdir, '*')).each do |path|
        FileUtils.rm_rf(path)
      end
    end

    it "fetches objects from the remote" do
      subject.fetch
      objectfiles = Dir.glob(File.join(objectdir, '*'))
      expect(objectfiles).to_not be_empty
    end
  end

  describe "listing branches" do
    before do
      subject.clone(remote)
    end

    it "lists all branches in alphabetical order" do
      expect(subject.branches).to eq(%w[0.9.x master])
    end
  end

  describe "determining ref type" do
    before do
      subject.clone(remote)
    end

    it "can infer the type of a branch ref" do
      expect(subject.__ref_type('master')).to eq :branch
    end

    it "can infer the type of a tag ref" do
      expect(subject.__ref_type('1.0.0')).to eq :tag
    end

    it "can infer the type of a commit" do
      expect(subject.__ref_type('3084373e8d181cf2fea5b4ade2690ba22872bd67')).to eq :commit
    end

    it "returns :unknown when the type cannot be inferred" do
      expect(subject.__ref_type('1.2.3')).to eq :unknown
    end
  end

  describe "retrieving refs" do
    before do
      subject.clone(remote)
    end

    it "can retrieve branches" do
      ref = subject.get_ref('master')
      expect(ref.ref_type).to eq :branch
    end

    it "can retrieve tags" do
      ref = subject.get_ref('1.0.0')
      expect(ref.ref_type).to eq :tag
    end

    it "can retrieve commits" do
      ref = subject.get_ref('3084373e8d181cf2fea5b4ade2690ba22872bd67')
      expect(ref.ref_type).to eq :commit
    end

    it "creates an empty ref when the ref can't be found" do
      ref = subject.get_ref('1.2.3')
      expect(ref.ref_type).to eq :unknown
    end
  end
end
