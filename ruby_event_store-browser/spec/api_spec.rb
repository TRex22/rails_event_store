require "spec_helper"
require "support/json_api_lint"


module RubyEventStore
  RSpec.describe Browser do
    include Rack::Test::Methods

    specify do
      event_store.publish(dummy_event, stream_name: "dummy")
      get "/streams/all"

      expect(last_response).to be_ok
      expect(parsed_body["data"]).to match_array([event_resource])

      get "/streams/dummy"

      expect(last_response).to be_ok
      expect(parsed_body["data"]).to match_array([event_resource])
    end

    specify do
      event_store.publish(dummy_event, stream_name: "dummy")
      get "/events/#{dummy_event.event_id}"

      expect(last_response).to be_ok
      expect(parsed_body["data"]).to match(event_resource)
    end

    specify do
      json = Browser::JsonApiEvent.new(dummy_event("a562dc5c-97c0-4fe9-8b81-10f9bd0e825f")).to_h

      expect(json).to match(
        id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        type: "events",
        attributes: {
          event_type: "DummyEvent",
          data: {
            foo: 1,
            bar: 2.0,
            baz: "3"
          },
          metadata: {}
        }
      )
    end

    specify "first page, newest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      event_store.publish(events, stream_name: "dummy")
      event_store.publish([DummyEvent.new])

      get "/streams/dummy"
      expect(parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/streams/dummy/head/forward/20",
        "next"  => "http://www.example.com/streams/dummy/#{first_page[19].event_id}/backward/20"
      })
      expect(parsed_body["data"].size).to eq(20)

      get "/streams/all"
      expect(parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/streams/all/head/forward/20",
        "next"  => "http://www.example.com/streams/all/#{first_page[18].event_id}/backward/20"
      })
      expect(parsed_body["data"].size).to eq(20)
    end

    specify "first page, newest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      event_store.publish(events, stream_name: "dummy")
      get "/streams/dummy/head/backward/20"

      expect(parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/streams/dummy/head/forward/20",
        "next"  => "http://www.example.com/streams/dummy/#{first_page.last.event_id}/backward/20"
      })
      expect(parsed_body["data"].size).to eq(20)
    end

    specify "first page, newest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      last_page  = events.reverse.drop(20)
      event_store.publish(events, stream_name: "dummy")
      get "/streams/dummy/#{last_page.first.event_id}/forward/20"

      expect(parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/streams/dummy/head/forward/20",
        "next"  => "http://www.example.com/streams/dummy/#{first_page.last.event_id}/backward/20"
      })
      expect(parsed_body["data"].size).to eq(20)
    end

    specify "last page, oldest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      last_page  = events.reverse.drop(20)
      event_store.publish([DummyEvent.new])
      event_store.publish(events, stream_name: "dummy")

      get "/streams/dummy/#{first_page.last.event_id}/backward/20"
      expect(parsed_body["links"]).to eq({
        "first" => "http://www.example.com/streams/dummy/head/backward/20",
        "prev"  => "http://www.example.com/streams/dummy/#{last_page.first.event_id}/forward/20" ,
      })
      expect(parsed_body["data"].size).to eq(20)

      get "/streams/all/#{first_page.last.event_id}/backward/20"
      expect(parsed_body["links"]).to eq({
        "first" => "http://www.example.com/streams/all/head/backward/20",
        "last"  => "http://www.example.com/streams/all/head/forward/20",
        "next"  => "http://www.example.com/streams/all/#{last_page.last.event_id}/backward/20",
        "prev"  => "http://www.example.com/streams/all/#{last_page.first.event_id}/forward/20" ,
      })
      expect(parsed_body["data"].size).to eq(20)
    end

    specify "last page, oldest events descending" do
      events    = 40.times.map { DummyEvent.new }
      last_page = events.reverse.drop(20)
      event_store.publish(events, stream_name: "dummy")
      get "/streams/dummy/head/forward/20"

      expect(parsed_body["links"]).to eq({
        "first" => "http://www.example.com/streams/dummy/head/backward/20",
        "prev"  => "http://www.example.com/streams/dummy/#{last_page.first.event_id}/forward/20",
      })
      expect(parsed_body["data"].size).to eq(20)
    end

    specify "non-edge page" do
      events = 41.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      next_page  = events.reverse.drop(20).take(20)
      event_store.publish(events, stream_name: "dummy")
      get "/streams/dummy/#{first_page.last.event_id}/backward/20"

      expect(parsed_body["links"]).to eq({
        "first" => "http://www.example.com/streams/dummy/head/backward/20",
        "last"  => "http://www.example.com/streams/dummy/head/forward/20",
        "next"  => "http://www.example.com/streams/dummy/#{next_page.last.event_id}/backward/20",
        "prev"  => "http://www.example.com/streams/dummy/#{next_page.first.event_id}/forward/20"
      })
      expect(parsed_body["data"].size).to eq(20)
    end

    specify "smaller than page size" do
      events = [DummyEvent.new, DummyEvent.new]
      event_store.publish(events, stream_name: "dummy")
      get "/streams/dummy"

      expect(parsed_body["links"]).to eq({})
      expect(parsed_body["data"].size).to eq(2)
    end

    specify "custom page size" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(5)
      next_page  = events.reverse.drop(5).take(5)

      event_store.publish(events, stream_name: "dummy")
      get "/streams/dummy/#{first_page.last.event_id}/backward/5"

      expect(parsed_body["links"]).to eq({
        "first" => "http://www.example.com/streams/dummy/head/backward/5",
        "last"  => "http://www.example.com/streams/dummy/head/forward/5",
        "next"  => "http://www.example.com/streams/dummy/#{next_page.last.event_id}/backward/5",
        "prev"  => "http://www.example.com/streams/dummy/#{next_page.first.event_id}/forward/5"
      })
      expect(parsed_body["data"].size).to eq(5)
    end

    specify "custom page size" do
      events = 40.times.map { DummyEvent.new }
      event_store.publish(events, stream_name: "dummy")
      get "/streams/all/head/forward/5"

      expect(parsed_body["data"].size).to eq(5)
    end

    specify "out of bounds beyond oldest" do
      events    = 40.times.map { DummyEvent.new }
      last_page = events.reverse.drop(20)
      event_store.publish(events, stream_name: "dummy")
      get "/streams/dummy/#{last_page.last.event_id}/backward/20"

      expect(parsed_body["links"]).to eq({})
      expect(parsed_body["data"].size).to eq(0)
    end

    specify "out of bounds beyond newest" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      event_store.publish(events, stream_name: "dummy")
      get "/streams/dummy/#{first_page.first.event_id}/forward/20"

      expect(parsed_body["links"]).to eq({})
      expect(parsed_body["data"].size).to eq(0)
    end

    def dummy_event(id = SecureRandom.uuid)
      @dummy_event ||= DummyEvent.new(
        event_id: id,
        data: {
          foo: 1,
          bar: 2.0,
          baz: "3"
        }
      )
    end

    def event_resource
      {
        "id" => dummy_event.event_id,
        "type" => "events",
        "attributes" => {
          "event_type" => "DummyEvent",
          "data" => {
            "foo" => 1,
            "bar" => 2.0,
            "baz" => "3"
          },
          "metadata" => {
            "timestamp" => dummy_event.metadata[:timestamp].iso8601(3)
          }
        }
      }
    end

    def parsed_body
      JSON.parse(last_response.body)
    end

    def get(*)
      header "Content-Type", "application/vnd.api+json"
      super
    end

    let(:app) { JsonApiLint.new(APP_BUILDER.call(event_store)) }
    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
  end
end
