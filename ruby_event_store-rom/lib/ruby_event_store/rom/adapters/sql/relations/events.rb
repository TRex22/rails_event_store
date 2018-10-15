module RubyEventStore
  module ROM
    module SQL
      module Relations
        class Events < ::ROM::Relation[:sql]
          schema(:event_store_events, as: :events, infer: true) do
            attribute :created_at, ::ROM::Types::Strict::Time.default { Time.now }
          end

          def create_changeset(tuples)
            events.changeset(Changesets::CreateEvents, tuples)
          end

          def update_changeset(tuples)
            events.changeset(Changesets::UpdateEvents, tuples)
          end
        end
      end
    end
  end
end
