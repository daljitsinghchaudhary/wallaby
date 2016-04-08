require 'rails_helper'

describe Wallaby::ActiveRecord::ModelFinder, clear: :object_space do
  describe '#all' do
    before do
      stub_const 'Airport', (Class.new do; def self.abstract_class?; false; end; end)
      stub_const 'Airline', (Class.new do; def self.abstract_class?; false; end; end)
      stub_const 'Airplane', (Class.new do; def self.abstract_class?; false; end; end)
      stub_const 'Airplane::HABTM_Airports', (Class.new do; def self.abstract_class?; false; end; end)
      stub_const 'AbstractAirport', (Class.new do; def self.abstract_class?; true; end; end)
    end

    it 'returns valid model classes in alphabetic order' do
      allow(ActiveRecord::Base).to receive(:subclasses).and_return [ Airport, Airplane, Airline ]
      expect(subject.send :all).to eq [ Airline, Airplane, Airport ]
    end

    context 'when there is abstract class' do
      it 'filters out abstract class' do
        allow(ActiveRecord::Base).to receive(:subclasses).and_return [ AbstractAirport ]
        expect(subject.send :all).to be_blank
      end
    end

    context 'when there is HABTM class' do
      it 'filters out HABTM class' do
        allow(ActiveRecord::Base).to receive(:subclasses).and_return [ Airplane::HABTM_Airports ]
        expect(subject.send :all).to be_blank
      end
    end

    context 'when there is anonymous class' do
      it 'filters out anonymous class' do
        anonymous_class = Class.new do
          def self.abstract_class?
            false
          end
        end
        allow(ActiveRecord::Base).to receive(:subclasses).and_return [ anonymous_class ]
        expect(subject.send :all).to be_blank
      end
    end
  end
end
