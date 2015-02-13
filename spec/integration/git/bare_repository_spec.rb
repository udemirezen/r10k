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

  subject { described_class.new(remote, basedir, dirname) }

  describe "checking for the presence of the repo" do
    it "exists if the repo is present" do
      subject.clone
      expect(subject.exist?).to be_truthy
    end

    it "doesn't exist if the repo is not present" do
      expect(subject.exist?).to be_falsey
    end
  end

  describe "cloning the repo" do
    it "creates the repo at the expected location" do
      subject.clone
      config = File.read(File.join(basedir, dirname, 'config'))
      expect(config).to match(remote)
    end

    # error case?
  end

  describe "updating the repo" do
    let(:objectdir) { objectdir = File.join(basedir, dirname, 'objects') }

    before do
      subject.clone
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
      subject.clone
    end

    it "lists all branches in alphabetical order" do
      expect(subject.branches).to eq(%w[0.9.x master])
    end
  end

  describe "listing tags" do
    before do
      subject.clone
    end

    it "lists all tags in alphabetical order" do
      expect(subject.tags).to eq(%w[0.9.0 0.9.0-rc1 1.0.0 1.0.1])
    end
  end

  describe "resolving refs" do
    before do
      subject.clone
    end

    it "can resolve branches" do
      expect(subject.__resolve('master')).to eq '157011a4eaa27f1202a9d94335ee4876b26d377e'
    end

    it "can resolve tags" do
      expect(subject.__resolve('1.0.0')).to eq '14cbb45ae3a5f764320b7e63f1a54a25a1ef6c9c'
    end

    it "can resolve commits" do
      expect(subject.__resolve('3084373e8d181cf2fea5b4ade2690ba22872bd67')).to eq '3084373e8d181cf2fea5b4ade2690ba22872bd67'
    end

    it "returns nil when the object cannot be resolved" do
      expect(subject.__resolve('1.2.3')).to be_nil
    end
  end

  describe "determining ref type" do
    before do
      subject.clone
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
end
