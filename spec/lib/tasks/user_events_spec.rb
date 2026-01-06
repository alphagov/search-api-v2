RSpec.describe "user events tasks" do
  describe "import events" do
    let(:import) { class_double(DiscoveryEngine::UserEvents::Import).as_stubbed_const(transfer_nested_constants: true) }

    around do |example|
      Timecop.freeze(Time.zone.local(1989, 12, 13, 1, 2, 3)) do
        example.call
      end
    end

    describe "user_events:import_yesterdays_events" do
      before do
        Rake::Task["user_events:import_yesterdays_events"].reenable
      end

      it "imports yesterday's events" do
        expect(import)
          .to receive(:import_all)
                .with(Date.new(1989, 12, 12))
                .once

        Rake::Task["user_events:import_yesterdays_events"].invoke
      end
    end

    describe "user_events:import_intraday_events" do
      before do
        Rake::Task["user_events:import_intraday_events"].reenable
      end

      it "imports today's events" do
        expect(import)
          .to receive(:import_all)
                .with(Date.new(1989, 12, 13))
                .once

        Rake::Task["user_events:import_intraday_events"].invoke
      end
    end

    describe "user_events:import_events_for_date" do
      let(:date) { Date.new(2000, 1, 1) }

      before do
        Rake::Task["user_events:import_events_for_date"].reenable
      end

      it "imports events for the given date" do
        expect(import)
          .to receive(:import_all)
                .with(date)
                .once

        Rake::Task["user_events:import_events_for_date"].invoke(date.to_s)
      end
    end
  end

  describe "purge events" do
    describe "user_events:purge_final_week_of_retention_period" do
      let(:purge) { class_double(DiscoveryEngine::UserEvents::Purge).as_stubbed_const(transfer_nested_constants: true) }

      before do
        Rake::Task["user_events:purge_final_week_of_retention_period"].reenable
      end

      it "purges user events from the final week of retention period" do
        expect(purge)
          .to receive(:purge_final_week_of_retention_period)
          .once

        Rake::Task["user_events:purge_final_week_of_retention_period"].invoke
      end
    end
  end
end
