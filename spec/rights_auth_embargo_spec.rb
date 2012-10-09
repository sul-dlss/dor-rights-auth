require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Dor::RightsAuth do
  
  describe "#embargoed?" do
    
    it "returns true if the object is currently embargoed" do
      tomorrow = Time.new + 60*60*24
      rights =<<-EOXML
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
      r.should be_embargoed
    end
    
    it "returns false if there is no embargo date" do
      rights =<<-EOXML
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
      r.should_not be_embargoed
    end
    
    it "returns false if the embargo date has passed" do
      yesterday = Time.new - 60*60*24
      rights =<<-EOXML
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
      r.should_not be_embargoed
    end
    
  end
  
end