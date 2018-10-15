module RubyEventStore
  module ROM
    module Memory
      class UnitOfWork < ROM::UnitOfWork
        def self.mutex
          @mutex ||= Mutex.new
        end

        def commit!(gateway, changesets, **options)
          self.class.mutex.synchronize do
            committed = []
            
            begin
              while changesets.size > 0
                changeset = changesets.shift
                relation = env.container.relations[changeset.relation.name]

                committed << [changeset, relation]

                changeset.commit
              end
            rescue StandardError
              committed.reverse.each do |changeset, relation|
                relation
                  .restrict(id: changeset.to_a.map { |e| e[:id] })
                  .command(:delete, result: :many).call
              end
              
              raise
            end
          end
        end
      end
    end
  end
end
