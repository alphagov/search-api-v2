RSpec.describe PublishingEventPipeline::Extractors::Content do
  describe "#call" do
    subject(:content) { described_class.new.call(message_hash) }

    describe "with basic top-level fields" do
      let(:message_hash) do
        {
          "details" => {
            "body" => "a",
            "description" => "b",
            "hidden_search_terms" => "c",
            "introduction" => "d",
            "introductory_paragraph" => "e",
            "more_information" => "f",
            "need_to_know" => "g",
            "summary" => "h",
            "title" => "i",
          },
        }
      end

      it { is_expected.to eq("a\nb\nc\nd\ne\nf\ng\nh\ni") }
    end

    describe "with hidden indexable content" do
      let(:message_hash) do
        {
          "details" => {
            "metadata" => {
              "hidden_indexable_content" => %w[x y z],
            },
          },
        }
      end

      it { is_expected.to eq("x\ny\nz") }
    end

    describe "with a project code" do
      let(:message_hash) do
        {
          "details" => {
            "metadata" => {
              "project_code" => "PRINCE2",
            },
          },
        }
      end

      it { is_expected.to eq("PRINCE2") }
    end

    describe "with contact groups" do
      let(:message_hash) do
        {
          "details" => {
            "contact_groups" => [
              { "title" => "x" },
              { "title" => "y" },
              { "title" => "z" },
            ],
          },
        }
      end

      it { is_expected.to eq("x\ny\nz") }
    end

    describe "with parts" do
      let(:message_hash) do
        {
          "details" => {
            "parts" => [
              { "title" => "x", "body" => "a" },
              { "title" => "y", "body" => "b" },
              { "title" => "z", "body" => "c" },
            ],
          },
        }
      end

      it { is_expected.to eq("x\na\ny\nb\nz\nc") }
    end

    describe "without any fields" do
      let(:message_hash) do
        {
          "details" => {},
        }
      end

      it { is_expected.to be_blank }
    end
  end
end
