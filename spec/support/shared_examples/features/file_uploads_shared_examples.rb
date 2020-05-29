# frozen_string_literal: true

RSpec.shared_examples 'file upload requests returns a succesful response' do
  it { expect(subject.code).to eq(200) }
end
