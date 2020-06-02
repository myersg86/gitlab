# frozen_string_literal: true

module Gitlab
  class UpdatedNotesPaginator
    LIMIT = 50

    attr_reader :notes

    def initialize(finder, last_fetched_at:)
      @last_fetched_at = last_fetched_at
      @now = Time.current

      notes, more = fetch_page(finder)
      if more
        init_middle_page(notes)
      else
        init_final_page(notes)
      end
    end

    def metadata
      { last_fetched_at: next_fetched_at, more: more }
    end

    private

    attr_reader :last_fetched_at, :more, :next_fetched_at, :now

    def fetch_page(finder)
      relation = finder
        .execute(fetch_overlap: fetch_overlap)
        .inc_relations_for_view

      notes = relation.at_most(LIMIT + 1).to_a

      return [notes, false] unless notes.size > LIMIT

      notes.pop # Remove the marker note

      # Add any notes with the same updated_at so pagination works as expected
      extra = relation
        .with_updated_at(notes.last.updated_at)
        .id_not_in(notes.map(&:id))
        .to_a

      [notes + extra, true]
    end

    def init_middle_page(notes)
      @more = true
      @next_fetched_at = notes.last.updated_at
      @notes = notes
    end

    def init_final_page(notes)
      @more = false
      @next_fetched_at = now
      @notes = notes
    end

    # Ignore the fetch overlap when fetching historic notes
    def fetch_overlap
      delta = [0, now.to_i - last_fetched_at.to_i].min

      if delta > 1.minute
        0
      else
        NotesFinder::FETCH_OVERLAP
      end
    end
  end
end
