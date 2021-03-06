# frozen_string_literal: true

require 'spec_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe Hyrax::PcdmCollection do
  subject(:collection) { described_class.new }

  it_behaves_like 'a Hyrax::PcdmCollection'

  describe '#human_readable_type' do
    it 'has a human readable type' do
      expect(collection.human_readable_type).to eq 'Collection'
    end
  end
end
