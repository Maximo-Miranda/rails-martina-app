# frozen_string_literal: true

module Documents
  class Uploaded < RailsEventStore::Event
    # data: { document_id:, remote_id:, gemini_document_path:, size_bytes: }
  end
end
