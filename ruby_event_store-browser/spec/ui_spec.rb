require 'spec_helper'

FooBarEvent = Class.new(::RubyEventStore::Event)

module RubyEventStore
  RSpec.describe Browser, type: :feature, js: true do
    before do
      Capybara.app = APP_BUILDER.call(event_store)
    end

    specify "main view", mutant: false do
      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: 'dummy')

      visit('/')
      
      expect(page).to have_content("Events in all")

      within('.browser__results') do
        click_on 'FooBarEvent'
      end

      within('.event__body') do
        expect(page).to have_content(foo_bar_event.event_id)
        expect(page).to have_content(%Q[timestamp: "#{foo_bar_event.metadata[:timestamp].iso8601(3)}" ])
        expect(page).to have_content(%Q[foo: "bar"])
      end
    end

    specify "stream view", mutant: false do
      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: 'foo/bar.xml')

      visit('/#streams/foo%2Fbar.xml')
      
      expect(page).to have_content("Events in foo/bar.xml")

      within('.browser__results') do
        click_on 'FooBarEvent'
      end

      within('.event__body') do
        expect(page).to have_content(foo_bar_event.event_id)
        expect(page).to have_content(%Q[timestamp: "#{foo_bar_event.metadata[:timestamp].iso8601(3)}"])
        expect(page).to have_content(%Q[foo: "bar"])
      end
    end

    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
  end
end
