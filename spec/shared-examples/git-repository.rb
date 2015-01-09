shared_examples_for "a git repository" do

  it "does not exist if the repo is not present" do
    expect(subject.exist?).to be_falsey
  end

  describe "listing tags" do
    before do
      subject.clone(remote)
    end

    it "lists all tags in alphabetical order" do
      expect(subject.tags).to eq(%w[0.9.0 0.9.0-rc1 1.0.0 1.0.1])
    end
  end

  describe "resolving refs" do
    before do
      subject.clone(remote)
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
