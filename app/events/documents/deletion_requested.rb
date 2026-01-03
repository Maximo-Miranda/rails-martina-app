# frozen_string_literal: true

module Documents
  class DeletionRequested < RailsEventStore::Event
    # data: { document_id:, remote_id:, gemini_document_path: }
  end
end
