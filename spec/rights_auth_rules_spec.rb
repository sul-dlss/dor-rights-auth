require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Dor::RightsAuth do
  
  describe "#world_rights" do
    
    it "returns the value and rule attribute for the entire object" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world rule="no-download"/>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      r = Dor::RightsAuth.parse rights
      
      world, rule = r.world_rights
      expect(world).to be
      expect(rule).to eq('no-download')
    end
  end
  
  describe "#stanford_only_rights" do
    
    it "returns the value and rule attribute for the entire object" do
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
      
      su_only, rule = r.stanford_only_rights
      expect(su_only).to be
      expect(rule).to eq('no-download')
    end
  end
  
  context "stanford-only full privileges, world download-only" do
    it "handles stuff" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <group>stanford</group>
              <world rule="no-download">stanford</world>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      @r = Dor::RightsAuth.parse rights
      
      su_only, rule = @r.stanford_only_rights
      expect(su_only).to be
      expect(rule).to be_nil
      expect(@r).to be_stanford_only_unrestricted
      
      world_val, world_rule = @r.world_rights
      expect(world_val).to be
      expect(world_rule).to eq('no-download')
      expect(@r).not_to be_world_unrestricted
    end
  end
  
  describe "#world_rights_for_file and #stanford_only_rights_for_file" do
    before(:each) do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
        </rightsMetadata>
        <rightsMetadata>
          <access type="read">
            <file>interview.doc</file>
            <machine>
              <group>stanford</group>
              <world rule="no-download"/>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      @r = Dor::RightsAuth.parse rights
    end
    
    it "returns the value and rule attribute for a single file" do
      world, rule = @r.world_rights_for_file('interview.doc')
      expect(world).to eq(true)
      expect(rule).to eq('no-download')
      
      su, su_rule = @r.stanford_only_rights_for_file('interview.doc')
      expect(su).to eq(true)
      expect(su_rule).to be_nil
    end
    
    it "defaults to object level rights when the questioned file does not have listed rights" do
      world, rule = @r.world_rights_for_file('object.doc')
      expect(world).to eq(true)
      expect(rule).to eq(nil)
      
      su, su_rule = @r.stanford_only_rights_for_file('object.doc')
      expect(su).to eq(false)
      expect(su_rule).to be_nil
    end
    
  end
  
  describe "#agent_rights_for_file" do
    before(:each) do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world/>
              <agent rule="objlevel">adminapp</agent>
            </machine>
          </access>
        </rightsMetadata>
        <rightsMetadata>
          <access type="read">
            <file>interview.doc</file>
            <machine>
              <group>stanford</group>
              <world rule="no-download"/>
              <agent>someapp1</agent>
              <agent rule="somerule">someapp2</agent>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      @r = Dor::RightsAuth.parse rights
    end
    
    it "returns agent rights for a given file" do
      agent_val, rule = @r.agent_rights_for_file('interview.doc', 'someapp1')
      expect(agent_val).to eq(true)
      expect(rule).to eq(nil)
      
      agent_val, rule = @r.agent_rights_for_file('interview.doc', 'someapp2')
      expect(agent_val).to eq(true)
      expect(rule).to eq('somerule')
      
      # if agent not listed for file, return false
      agent_val, rule = @r.agent_rights_for_file('interview.doc', 'unauthorized-app')
      expect(agent_val).to eq(false)
      expect(rule).to eq(nil)
    end
    
    it "returns object level rights if the file does not have listed rights" do
       agent_val, rule = @r.agent_rights_for_file('freetosee.doc', 'adminapp')
       expect(agent_val).to eq(true)
       expect(rule).to eq('objlevel')
  
       agent_val, rule = @r.agent_rights_for_file('freetosee.doc', 'someapp2')
       expect(agent_val).to eq(false)
       expect(rule).to eq(nil)
    end
    
  end
  
end
