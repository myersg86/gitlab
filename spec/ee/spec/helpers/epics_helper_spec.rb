require 'spec_helper'

describe EpicsHelper do
  describe '#epic_initial_data' do
    it 'returns the correct hash' do
      expect(epic_initial_data).to eq({})
    end
  end
end
