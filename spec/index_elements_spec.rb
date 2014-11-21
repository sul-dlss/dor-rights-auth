require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Dor::RightsAuth do

  describe "#world_rights" do

    it "Missing-discover world-read single rule" do
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
      r = Dor::RightsAuth.parse(rights, true)

      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to include("no_discover_access")
      expect(i[:primary]).to eq "dark"
      expect(i[:terms]  ).to include("has_rule", "world|no-download")
      expect(i[:terms]  ).not_to include("world_read", "none_read", "none_discover")
    end

    it "Double dark double none" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <none/>
            </machine>
          </access>
          <access type="discover">
            <machine>
              <none/>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      r = Dor::RightsAuth.parse(rights, true)

      i = r.index_elements
      puts i
      expect(i).to be
      expect(i[:errors] ).to be_empty
      expect(i[:primary]).to eq "dark"
      expect(i[:terms]  ).to include("none_read", "none_discover")
      expect(i[:terms]  ).not_to include("has_rule", "world_read", "world_discover")
    end

    it "World-discover world-read single rule" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world rule="no-download"/>
            </machine>
          </access>
          <access type="discover">
            <machine>
              <world/> <!--  metadata is publicly visible by policy; in theory could get as messy as "read" access, but we do not support this! -->
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      r = Dor::RightsAuth.parse(rights, true)

      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to be_empty
      expect(i[:primary]).to eq "complicated"
      expect(i[:terms]  ).to include("has_rule", "world_discover")
      expect(i[:terms]  ).not_to include("world_read", "none_read", "none_discover")
    end
  end

  describe "#stanford_only no-download" do

    it "returns the value and rule attribute for the entire object" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <group rule="no-download">stanford</group>
            </machine>
          </access>
          <access type="discover">
            <machine>
              <world/> <!--  metadata is publicly visible by policy; in theory could get as messy as "read" access, but we do not support this! -->
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      r = Dor::RightsAuth.parse(rights, true)
      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to be_empty
      expect(i[:primary]).to eq "complicated"
      expect(i[:terms]  ).to include("has_rule", "has_group_rights", "group|stanford_with_rule", "world_discover")
      expect(i[:terms]  ).not_to include("world_read", "none_read", "none_discover")
    end
  end

  describe "stanford-only full privileges, world download-only" do
    it "handles stanford" do
      rights =<<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/> <!--  metadata is publicly visible by policy; in theory could get as messy as "read" access, but we do not support this! -->
            </machine>
          </access>
          <access type="read">
            <machine>
              <group>stanford</group>
              <world rule="no-download"/>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      r = Dor::RightsAuth.parse(rights, true)

      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to be_empty
      expect(i[:primary]).to eq "stanford"
      expect(i[:terms]  ).to include("has_rule", "has_group_rights", "group|stanford")
      expect(i[:terms]  ).not_to include("world_read", "none_read", "none_discover")
    end
  end

  describe "#world_rights_for_file and #stanford_only_rights_for_file" do
    rights =<<-EOXML
    <objectType>
      <rightsMetadata>
        <access type="discover"><machine><world/></machine></access>    <!-- our most common "discover" -->
        <access type="read">
          <machine>
            <world/>
          </machine>
        </access>
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
    r = Dor::RightsAuth.parse(rights, true)

    it "single file" do
      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to be_empty
      expect(i[:primary]).to eq "world"
      ["world_read", "world_discover", "has_file_rights", "file_has_group", "file_has_world", "file_rights_for_group|1", "file_rights_for_world|1"].each { |x|
        expect(i[:terms]).to include(x)
      }
      expect(i[:terms]).not_to include("none_read", "none_discover")
    end

  end

  describe "#agent_rights" do
    rights =<<-EOXML
    <objectType>
      <rightsMetadata>
        <access type="discover"><machine><world/></machine></access>    <!-- our most common "discover" -->
        <access type="read">
          <machine>
            <world/>
            <agent rule="objlevel">adminapp</agent>
          </machine>
        </access>
        <access type="read">
          <file>interview.doc</file>
          <machine>
            <group>stanford</group>
            <world rule="no-download"/>
            <agent>someapp1</agent>
            <agent rule="somerule">someapp2</agent>
          </machine>
        </access>
        <access type="read">
          <file>other.doc</file>
          <machine>
            <group>other</group>
            <group>stanford</group>
            <world rule="no-download"/>
          </machine>
        </access>
        <access type="read">
          <file>last.doc</file>
          <machine>
            <group>stanford</group>
            <world rule="no-download"/>
          </machine>
        </access>
      </rightsMetadata>
    </objectType>
    EOXML
    r = Dor::RightsAuth.parse(rights, true)

    it "handles agent rights at multiple levels" do
      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to be_empty
      expect(i[:primary]).to eq "world"
      ["world_read", "world_discover", "has_rule", "has_file_rights",
          "file_has_group", "file_has_world", "file_has_agent",
          "file_rights_count|3", "file_rights_for_agent|2", "file_rights_for_group|4", "file_rights_for_world|3", ].each { |x|
        expect(i[:terms]).to include(x)
      }
      expect(i[:terms]).not_to include("none_read", "none_discover")
    end
  end

end
