RSpec.describe DiscoveryEngine::Query::UserLabels do
  subject { described_class.from_user_agent(user_agent) }

  context "when user agent is from a GOV.UK web app" do
    context "with gds-api-adapters finder-frontend user agent" do
      let(:user_agent) { "gds-api-adapters/99.2.0 (finder-frontend)" }

      it { is_expected.to have_attributes(consumer: "finder-frontend", consumer_group: "web") }
    end

    context "with different app names" do
      let(:user_agent) { "gds-api-adapters/1.0.0 (government-frontend)" }

      it { is_expected.to have_attributes(consumer: "government-frontend", consumer_group: "web") }
    end

    context "with different version numbers" do
      let(:user_agent) { "gds-api-adapters/123.45.67 (collections)" }

      it { is_expected.to have_attributes(consumer: "collections", consumer_group: "web") }
    end
  end

  context "when user agent is from iOS app" do
    context "with basic govuk_ios user agent" do
      let(:user_agent) { "govuk_ios/1.0.0" }

      it { is_expected.to have_attributes(consumer: "app-ios", consumer_group: "app") }
    end

    context "with govuk_ios user agent with additional info" do
      let(:user_agent) { "govuk_ios/2.5.1 (iPhone; iOS 15.0)" }

      it { is_expected.to have_attributes(consumer: "app-ios", consumer_group: "app") }
    end
  end

  context "when user agent is from Android app" do
    context "with basic okhttp user agent" do
      let(:user_agent) { "okhttp/4.9.0" }

      it { is_expected.to have_attributes(consumer: "app-android", consumer_group: "app") }
    end

    context "with okhttp user agent with additional info" do
      let(:user_agent) { "okhttp/4.9.0 (Android 11)" }

      it { is_expected.to have_attributes(consumer: "app-android", consumer_group: "app") }
    end
  end

  context "when user agent is from other sources" do
    context "with browser user agent" do
      let(:user_agent) { "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" }

      it { is_expected.to have_attributes(consumer: "other", consumer_group: "other") }
    end

    context "with curl user agent" do
      let(:user_agent) { "curl/7.68.0" }

      it { is_expected.to have_attributes(consumer: "other", consumer_group: "other") }
    end

    context "with empty user agent" do
      let(:user_agent) { "" }

      it { is_expected.to have_attributes(consumer: "other", consumer_group: "other") }
    end

    context "with nil user agent" do
      let(:user_agent) { nil }

      it { is_expected.to have_attributes(consumer: "other", consumer_group: "other") }
    end
  end
end
