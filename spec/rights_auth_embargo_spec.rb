# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::RightsAuth do
  subject(:instance) { Dor::RightsAuth.parse rights }

  describe '#embargoed?' do
    context 'when the object is currently embargoed' do
      let(:tomorrow) { Time.new + 60 * 60 * 24 }
      let(:rights) do
        <<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <machine>
                <embargoReleaseDate>#{tomorrow.strftime('%Y-%m-%d')}</embargoReleaseDate>
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML
      end

      it 'returns true' do
        expect(instance).to be_embargoed
      end
    end

    context 'when there is no embargo date' do
      let(:rights) do
        <<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML
      end

      it 'returns false' do
        expect(instance).not_to be_embargoed
      end
    end

    context 'when the embargo date has passed' do
      let(:yesterday) { Time.new - 60 * 60 * 24 }
      let(:rights) do
        <<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <machine>
                <embargoReleaseDate>#{yesterday.strftime('%Y-%m-%d')}</embargoReleaseDate>
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML
      end

      it 'returns false' do
        expect(instance).not_to be_embargoed
      end
    end
  end

  describe '.parse' do
    context 'when the embargo date is empty' do
      let(:rights) do
        <<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <machine>
                <embargoReleaseDate></embargoReleaseDate>
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML
      end

      it 'throws exception' do
        expect { Dor::RightsAuth.parse rights }.to raise_error(ArgumentError, 'no time information in ""')
      end
    end

    context 'when the embargo date is illegal' do
      let(:rights) do
        <<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <machine>
                <embargoReleaseDate>9999-44-12</embargoReleaseDate>
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML
      end

      it 'throws exception' do
        expect { Dor::RightsAuth.parse rights }.to raise_error(ArgumentError, /rgument out of range/)
      end
    end
  end

  describe '#embargo_release_date' do
    subject { instance.embargo_release_date }

    let(:tomorrow) { (Time.new + 60 * 60 * 24).strftime('%Y-%m-%d') }
    let(:rights) do
      <<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <embargoReleaseDate>#{tomorrow}</embargoReleaseDate>
              <group>stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
    end

    it { is_expected.to eq Time.parse(tomorrow) }
  end
end
