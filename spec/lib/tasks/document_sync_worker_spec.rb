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

  describe "document_sync_worker:create_queue" do
    let(:task_name) { "document_sync_worker:create_queue" }

    let(:session) do
      instance_double(Bunny::Session, create_channel: channel).tap do |double|
        allow(double).to receive(:start).and_return(double)
      end
    end
    let(:channel) { instance_double(Bunny::Channel) }
    let(:exchange) { instance_double(Bunny::Exchange, name: "published_documents") }

    before do
      allow(Bunny).to receive(:new).and_return(session)
      allow(Bunny::Exchange).to receive(:new).with(channel, :topic, "published_documents").and_return(exchange)
      Rake::Task[task_name].reenable
    end

    context "when the environment is not development" do
      before do
        allow(Rails.env).to receive(:development?).and_return(false)
      end

      it "raises an error" do
        message = "This task should only be run in development"
        expect { Rake::Task[task_name].invoke }.to raise_error(message)
      end
    end

    context "when the environment is development" do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "creates the exchange and queue" do
        ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME: "my queue" do
          name = ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME")
          queue = instance_double(Bunny::Queue, name: name, bind: nil)

          allow(channel).to receive(:queue).with(name).and_return(queue)

          Rake::Task[task_name].invoke
          expect(channel).to have_received(:queue).with(name)
          expect(queue).to have_received(:bind).with(exchange, routing_key: "*.*")
        end
      end
    end
  end
end
