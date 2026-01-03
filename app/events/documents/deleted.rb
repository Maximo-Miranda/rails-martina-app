# frozen_string_literal: true

module Documents
  class Deleted < RailsEventStore::Event
    # data: { document_id: }
  end
end
