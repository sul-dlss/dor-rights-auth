# frozen_string_literal: true

require 'spec_helper'

describe Dor::RightsAuth do

  describe '#embargoed?' do

    it 'returns true if the object is currently embargoed' do
      tomorrow = Time.new + 60 * 60 * 24
      rights = <<-EOXML
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

      r = Dor::RightsAuth.parse rights
      expect(r).to be_embargoed
    end

    it 'returns false if there is no embargo date' do
      rights = <<-EOXML
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

      r = Dor::RightsAuth.parse rights
      expect(r).not_to be_embargoed
    end

    it 'parse throws exception on empty embargo date' do
      rights = <<-EOXML
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

      expect { Dor::RightsAuth.parse rights }.to raise_error(ArgumentError, 'no time information in ""')
    end

    it 'parse throws exception on illegal embargo date' do
      rights = <<-EOXML
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

      expect { Dor::RightsAuth.parse rights }.to raise_error(ArgumentError, /rgument out of range/)
    end

    it 'returns false if the embargo date has passed' do
      yesterday = Time.new - 60 * 60 * 24
      rights = <<-EOXML
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

      r = Dor::RightsAuth.parse rights
      expect(r).not_to be_embargoed
    end

  end

end
