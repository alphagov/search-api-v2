RSpec.describe "Document synchronisation tasks" do
  describe "document_sync_worker:run" do
    let(:consumer) { instance_double(GovukMessageQueueConsumer::Consumer) }

    before do
      allow(GovukMessageQueueConsumer::Consumer)
        .to receive(:new)
        .and_return(consumer)

      allow(Rails.logger).to receive(:info)
      Rake::Task["document_sync_worker:run"].reenable
    end

    it "processes a document" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME: "my queue" do
        expect(consumer)
          .to receive(:run)
          .once

        expect(Rails.logger).to receive(:info).with(
          "Starting document sync worker",
        )

        Rake::Task["document_sync_worker:run"].invoke
      end
    end

    context "when the task is interrupted" do
      it "catches the interrupt and logs it to the Rails logger" do
        ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME: "my queue" do
          allow(consumer)
            .to receive(:run)
            .and_raise(Interrupt)

          expect(Rails.logger).to receive(:info).with(
            "Stopping document sync worker (received interrupt)",
          )

          Rake::Task["document_sync_worker:run"].invoke
        end
      end
    end

    context "when the task fails with a RabbitMQ error" do
      let(:error) { AMQ::Protocol::EmptyResponseError.new("Empty response") }

      it "logs the error to Rails logger and exits the task" do
        ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME: "my queue" do
          allow(consumer)
            .to receive(:run)
            .and_raise(error)

          allow(Rails.logger).to receive(:warn)

          expect(Rails.logger).to receive(:warn).with(
            "Stopping document sync worker: 'Empty response'",
          )

          expect { Rake::Task["document_sync_worker:run"].invoke }.to raise_error(SystemExit)
        end
      end
    end
  end
end
