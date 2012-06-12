require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Dor::RightsAuth do
  
  describe "#stanford_only_unrestricted?" do
    
    it "returns true if the object has stanford-only read access without a rule attribute" do
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
      r.stanford_only_unrestricted?.should be_true
    end
    
    it "returns false if the object does not have stanford-only read access" do
      xml =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      rights = Dor::RightsAuth.parse xml
      rights.stanford_only_unrestricted?.should be_false
    end
    
    it "returns false if the object has stanford-only read access with a rule attribute" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <group rule="no-download">stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML

      r = Dor::RightsAuth.parse rights
      r.stanford_only_unrestricted?.should be_false
    end
    
    it "returns false when there is file-level stanford-only access but object-level world access" do
      xml =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <file>interviews1.doc</file> 
            <file>interviews2.doc</file> 
            <machine> 
              <group>stanford</group> 
            </machine>
          </access>
          <access type="read">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      rights = Dor::RightsAuth.parse xml
      rights.should_not be_stanford_only_unrestricted
    end
  end
      
  describe "#public_unrestricted?" do
    
    it "returns true if this object has world readable visibility" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.should be_public_unrestricted
    end
    
    it "returns false if there is no machine readable world visibility" do
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
      r.should_not be_public_unrestricted
    end
    
    it "returns false if there is no machine/world access WITHOUT a rule attribute" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world rule="no-download" />
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.should_not be_public_unrestricted
    end
    
    it "returns false if the rights metadata does not contain a read block" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
        <access type="discover">
          <machine>
            <world />
          </machine>
        </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.should_not be_public_unrestricted
    end
    
    it "returns false when there is file-level world access but object-level stanford-only access" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <file>public1.doc</file> 
            <file>public2.doc</file> 
            <machine> 
              <world />
            </machine>
          </access>
          <access type="read">
            <machine>
              <group>stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.should_not be_public_unrestricted
    end
    
  end
  
  describe "#readable?" do
    
    it "returns true if the rights metadata contains a read block" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.should be_readable
    end
    
    it "returns false if the rights metadata does not contain a read block" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.should_not be_readable
    end
    
    it "returns false if there's only a read access block with files, but no object level read access" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world />
            </machine>
          </access>
          <access type="read">
            <file>some_public_file.doc</file>
            <machine>
              <world/>
            </machine>
          </access>
          <!-- No object level read access block -->
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.should_not be_readable
    end
    
  end
  
  describe "#allowed_read_agent?" do
    it "returns true if the passed in user is an allowed read agent" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <agent>app-name</agent>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.allowed_read_agent?('app-name').should be
    end
    
    it "handles more than one agent" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <agent>app-name</agent>
              <agent>app2</agent>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.allowed_read_agent?('app2').should be
    end
    
    it "returns false if the passed in user is NOT an allowed read agent" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <agent>app-name</agent>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.allowed_read_agent?('another-app-name').should_not be
    end
    
    it "returns false if there is no read agent in rightsMetadata" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      r = Dor::RightsAuth.parse rights
      r.allowed_read_agent?('another-app-name').should_not be
    end
    
  end

  describe "#stanford_only_unrestricted_file?" do
    
    before(:all) do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <file>interviews1.doc</file> 
            <file>interviews2.doc</file> 
            <machine> 
              <group>stanford</group> 
            </machine>
          </access>
          <access type="read">
            <file>su-only-no-download.doc</file> 
            <machine> 
              <group rule="no-download">stanford</group> 
            </machine>
          </access>
          <access type="read">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      
      @r = Dor::RightsAuth.parse rights
    end
    
    it "returns true if a file has stanford-only read access" do
       @r.should be_stanford_only_unrestricted_file('interviews1.doc')
    end
    
    it "returns the value of object level #stanford_only_unrestricted? if the queried file is not listed " do
      @r.should_not be_stanford_only_unrestricted_file('object-level-rights.xml')
    end
    
    it "returns false if a file is stanford-only AND has a rule attribute" do
      @r.should_not be_stanford_only_unrestricted_file('su-only-no-download.doc')
    end
  end
  
  describe "#public_unrestricted_file?" do
    
    context "stanford-only object level read-access, but world access to individual files" do
    
      before(:all) do
        rights =<<-EOXML
        <objectType>
          <rightsMetadata>
            <access type="read">
              <file>interviews1.doc</file> 
              <file>interviews2.doc</file> 
              <machine> 
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        </objectType>
        EOXML

        @r = Dor::RightsAuth.parse rights
      end
    
      it "returns true if the file has world unrestricted read access" do
        @r.should be_public_unrestricted_file('interviews2.doc')
      end
    
      it "returns the value of object level #public? if the queried file is not listed" do
        @r.should_not be_public_unrestricted_file('stanford-only-file.txt')
      end
          
    end
  end

end