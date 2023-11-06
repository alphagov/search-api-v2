RSpec.describe PublishingApi::Metadata do
  subject(:concern_consumer) { Struct.new(:document_hash).include(described_class) }

  describe "#metadata" do
    subject(:extracted_metadata) { concern_consumer.new(document_hash).metadata }

    describe "content_id" do
      subject(:extracted_content_id) { extracted_metadata[:content_id] }

      let(:document_hash) { { content_id: "000-000-000" } }

      it { is_expected.to eq("000-000-000") }
    end

    describe "title" do
      subject(:extracted_title) { extracted_metadata[:title] }

      let(:document_hash) { { title: "Hello world" } }

      it { is_expected.to eq("Hello world") }
    end

    describe "description" do
      subject(:extracted_description) { extracted_metadata[:description] }

      let(:document_hash) { { description: "Lorem ipsum dolor sit amet." } }

      it { is_expected.to eq("Lorem ipsum dolor sit amet.") }
    end

    describe "additional_searchable_text" do
      subject(:additional_searchable_text) { extracted_metadata[:additional_searchable_text] }

      let(:document_hash) do
        {
          details: {
            acronym: "BA",
            metadata: {
              registration: "G-CIVY",
              aircraft_type: "Boeing 747-436",
            },
          },
        }
      end

      it { is_expected.to eq("BA\nBoeing 747-436\nG-CIVY") }
    end

    describe "link" do
      subject(:extracted_link) { extracted_metadata[:link] }

      context "with a base_path" do
        let(:document_hash) { { base_path: "/test" } }

        it { is_expected.to eq("/test") }
      end

      context "with an external URL" do
        let(:document_hash) { { details: { url: "https://liverpool.gov.uk/" } } }

        it { is_expected.to eq("https://liverpool.gov.uk/") }
      end

      context "with both a base_path and an external URL" do
        let(:document_hash) do
          { base_path: "/test", details: { url: "https://liverpool.gov.uk/" } }
        end

        it { is_expected.to eq("/test") }
      end

      context "without a base_path or external URL" do
        let(:document_hash) { {} }

        it { is_expected.to be_nil }
      end
    end

    describe "url" do
      subject(:extracted_url) { extracted_metadata[:url] }

      before do
        allow(Plek).to receive(:new).and_return(
          instance_double(Plek, website_root: "https://test.gov.uk"),
        )
      end

      context "with a base_path" do
        let(:document_hash) { { base_path: "/test" } }

        it { is_expected.to eq("https://test.gov.uk/test") }
      end

      context "with an external URL" do
        let(:document_hash) { { details: { url: "https://liverpool.gov.uk/" } } }

        it { is_expected.to eq("https://liverpool.gov.uk/") }
      end

      context "with both a base_path and an external URL" do
        let(:document_hash) do
          { base_path: "/test", details: { url: "https://liverpool.gov.uk/" } }
        end

        it { is_expected.to eq("https://test.gov.uk/test") }
      end

      context "without a base_path or external URL" do
        let(:document_hash) { {} }

        it { is_expected.to be_nil }
      end
    end

    describe "public_timestamp" do
      subject(:extracted_public_timestamp) { extracted_metadata[:public_timestamp] }

      let(:document_hash) { { public_updated_at: "2012-02-01T00:00:00Z" } }

      it { is_expected.to eq(1_328_054_400) }

      context "without a public_timestamp" do
        let(:document_hash) { {} }

        it { is_expected.to be_nil }
      end
    end

    describe "document_type" do
      subject(:extracted_document_type) { extracted_metadata[:document_type] }

      let(:document_hash) { { document_type: "foo_bar" } }

      it { is_expected.to eq("foo_bar") }
    end

    describe "content_purpose_supergroup" do
      subject(:extracted_content_purpose_supergroup) { extracted_metadata[:content_purpose_supergroup] }

      let(:document_hash) { { content_purpose_supergroup: "foo_bar" } }

      it { is_expected.to eq("foo_bar") }
    end

    describe "part_of_taxonomy_tree" do
      subject(:extracted_part_of_taxonomy_tree) { extracted_metadata[:part_of_taxonomy_tree] }

      context "with a set of taxon links" do
        let(:document_hash) { { links: { taxons: %w[0000 ffff] } } }

        it { is_expected.to eq(%w[0000 ffff]) }
      end

      context "without taxon links" do
        let(:document_hash) { { "links": {} } }

        it { is_expected.to be_nil }
      end
    end

    describe "is_historic" do
      subject(:extracted_is_historic) { extracted_metadata[:is_historic] }

      context "when the document is non-political" do
        let(:document_hash) { { details: {} } }

        it { is_expected.to eq(0) }
      end

      context "when the document is political" do
        let(:document_hash) do
          {
            details: { political: true },
            expanded_links:,
          }
        end

        context "without link to a government" do
          let(:expanded_links) { {} }

          it { is_expected.to eq(0) }
        end

        context "with a link to the current government" do
          let(:expanded_links) { { government: [{ details: { current: true } }] } }

          it { is_expected.to eq(0) }
        end

        context "with a link to a previous government" do
          let(:expanded_links) { { government: [{ details: { current: false } }] } }

          it { is_expected.to eq(1) }
        end
      end
    end

    describe "government_name" do
      subject(:extracted_government_name) { extracted_metadata[:government_name] }

      let(:document_hash) { { expanded_links: } }

      context "without link to a government" do
        let(:expanded_links) { {} }

        it { is_expected.to be_nil }
      end

      context "with a link to a government" do
        let(:expanded_links) { { government: [{ title: "2096 Something Party government" }] } }

        it { is_expected.to eq("2096 Something Party government") }
      end
    end

    describe "organisation_state" do
      subject(:extracted_organisation_state) { extracted_metadata[:organisation_state] }

      let(:document_hash) { { details: } }

      context "without an organisation state" do
        let(:details) { {} }

        it { is_expected.to be_nil }
      end

      context "with an organisation state" do
        let(:details) { { organisation_govuk_status: { status: "blub" } } }

        it { is_expected.to eq("blub") }
      end
    end

    describe "locale" do
      subject(:extracted_locale) { extracted_metadata[:locale] }

      let(:document_hash) { { locale: "en" } }

      it { is_expected.to eq("en") }
    end

    describe "parts" do
      subject(:extracted_parts) { extracted_metadata[:parts] }

      let(:document_hash) { { details: { parts: } } }

      context "when the document has no parts" do
        let(:parts) { nil }

        it { is_expected.to be_nil }
      end

      context "when the document has parts" do
        let(:parts) do
          [
            {
              title: "Part 1",
              slug: "/part-1",
              body: [
                {
                  content: "Part 1 body",
                  content_type: "text/simples",
                },
                {
                  content: "<div class=\"lipsum\">Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur <blink>tincidunt sem erat</blink>, eget blandit urna porta ac. Mauris lobortis tincidunt dui at pharetra.</div>",
                  content_type: "text/html",
                },
              ],
            },
            {
              title: "Part 2",
              slug: "/part-2",
              body: [
                {
                  content: "I have no HTML content :(",
                  content_type: "text/simples",
                },
              ],
            },
          ]
        end

        it "contains the expected titles" do
          expect(extracted_parts.map { _1[:title] }).to eq(["Part 1", "Part 2"])
        end

        it "contains the expected slugs" do
          expect(extracted_parts.map { _1[:slug] }).to eq(%w[/part-1 /part-2])
        end

        it "contains the expected body with HTML stripped and truncated" do
          expect(extracted_parts.map { _1[:body] }).to eq([
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur…",
            "",
          ])
        end
      end
    end
  end
end
