# frozen_string_literal: true

require 'spec_helper'

describe Dor::RightsAuth do

  describe '#index_elements catches errors' do

    it 'Missing-discover world-read single rule' do
      rights = <<-EOXML
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
      expect(i[:errors] ).to include('no_discover_access')
      expect(i[:primary]).to eq 'dark'
      expect(i[:terms]  ).to include('has_rule', 'world|no-download', 'world_read')
      expect(i[:terms]  ).not_to include('none_read', 'none_discover')
    end

    it 'Missing-read' do
      rights = <<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="discover">
            <machine><world/></machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      r = Dor::RightsAuth.parse(rights, true)
      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to include('no_read_access')
      expect(i[:primary]).to eq 'citation'
      expect(i[:terms]  ).to include('world_discover')
      expect(i[:terms]  ).not_to include('has_rule', 'world_read', 'world|no-download', 'none_read', 'none_discover')
    end

    it 'Missing-discover machine' do
      rights = <<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world rule="no-download"/>
            </machine>
          </access>
          <access type="discover">
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      r = Dor::RightsAuth.parse(rights, true)
      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to include('no_discover_machine')
      expect(i[:primary]).to eq 'dark'
      expect(i[:terms]  ).to include('has_rule', 'world|no-download', 'world_read')
      expect(i[:terms]  ).not_to include('none_read', 'none_discover')
    end

    it 'No machines (read or discover)' do
      rights = <<-EOXML
      <objectType>
        <rightsMetadata>
          <access type="read">
          </access>
          <access type="discover">
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      r = Dor::RightsAuth.parse(rights, true)
      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to include('no_discover_machine', 'no_read_machine')
      expect(i[:primary]).to eq 'dark'
      expect(i[:terms]  ).not_to include('has_rule', 'world|no-download', 'world_read', 'none_read', 'none_discover')
    end
  end

  describe '#index_elements' do
    it 'Double dark double none, dark file' do
      rights = <<-EOXML
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
          <access type="read">
            <file>dark_file</file>
            <machine>
              <none/>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
      r = Dor::RightsAuth.parse(rights, true)
      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to be_empty
      expect(i[:primary]).to eq 'dark'
      expect(i[:terms]  ).to include('none_read', 'none_discover', 'none_read_file')
      expect(i[:terms]  ).not_to include('has_rule', 'world_read', 'world_discover')
    end

    it 'World-discover world-read single rule' do
      rights = <<-EOXML
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
      expect(i[:primary]).to eq 'world_qualified'
      expect(i[:terms]  ).to include('has_rule', 'world_discover', 'world|no-download', 'world_read')
      expect(i[:terms]  ).not_to include('none_read', 'none_discover')
    end
  end

  describe '#stanford_only no-download' do
    it 'returns the value and rule attribute for the entire object' do
      rights = <<-EOXML
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
      expect(i[:primary]).to eq 'access_restricted_qualified'
      expect(i[:terms]  ).to include('has_rule', 'has_group_rights', 'group|stanford_with_rule', 'world_discover')
      expect(i[:terms]  ).not_to include('world_read', 'none_read', 'none_discover')
    end
  end

  describe 'stanford-only full privileges, world download-only' do
    it 'handles stanford' do
      rights = <<-EOXML
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
      expect(i[:primary]).to eq 'world_qualified'
      expect(i[:terms]  ).to include('has_rule', 'has_group_rights', 'group|stanford', 'world_read')
      expect(i[:terms]  ).not_to include('none_read', 'none_discover')
    end
  end

  describe 'controlled_digital_lending' do
    let(:rights) do
      <<-XML
      <objectType>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <cdl>
                <group rule="no-download">stanford</group>
              </cdl>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      XML
    end
    it 'adds the cdl_none rule' do
      r = Dor::RightsAuth.parse(rights, true)
      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to be_empty
      expect(i[:primary]).to eq 'controlled digital lending'
      expect(i[:terms]  ).to include('world_discover', 'has_rule', 'cdl_none', 'profile:cdl1')
      expect(i[:terms]  ).not_to include('none_read', 'none_discover')
    end
  end

  describe '#world_rights_for_file and #stanford_only_rights_for_file' do
    rights = <<-EOXML
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
    it 'single file' do
      i = r.index_elements
      expect(i).to be
      expect(i[:errors] ).to be_empty
      expect(i[:primary]).to eq 'world'
      ['world_read',
       'world_discover',
       'has_file_rights',
       'file_has_group',
       'file_has_world',
       'file_rights_for_group|1',
       'file_rights_for_world|1'].each { |x|
        expect(i[:terms]).to include(x)
      }
      expect(i[:terms]).not_to include('none_read', 'none_discover')
    end
  end

  describe 'multiple orthogonal rights types' do
    let(:rights) do
      <<-EOXML
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
              <location>reading_rm</location>
            </machine>
          </access>
          <access type="read">
            <file>other.doc</file>
            <machine>
              <group>other</group>
              <group>stanford</group>
              <world rule="no-download"/>
              <location rule="new-rule">new_reading_rm</location>
            </machine>
          </access>
          <access type="read">
            <file>last.doc</file>
            <machine>
              <group rule="no-download">stanford</group>
              <world rule="no-download"/>
              <location rule="no-download">reading_rm</location>
            </machine>
          </access>
        </rightsMetadata>
      </objectType>
      EOXML
    end
    let(:r) { Dor::RightsAuth.parse(rights, true) }
    let(:i) { r.index_elements }

    it 'exists and has no errors' do
      expect(i).to be
      expect(i[:errors] ).to be_empty
    end

    it 'has the expected primary value' do
      expect(i[:primary]).to eq 'world_qualified'
    end

    it 'has the expected terms' do
      ['world_read', 'world_discover', 'has_rule', 'has_file_rights',
       'file_has_group', 'file_has_world', 'file_has_agent',
       'file_rights_count|3', 'file_rights_for_agent|2',
       'file_rights_for_group|4', 'file_rights_for_world|3'].each { |x|
        expect(i[:terms]).to include(x)
      }
      expect(i[:terms]).not_to include('none_read', 'none_discover')
    end

    it 'has the expected world-specific values' do
      expect(i[:file_world_qualified]).to eq [{ :rule => 'no-download' }] # all the files are no-download
      expect(i[:obj_world_qualified]).to eq [{ :rule => nil }] # the object is world read with no rule
    end

    it 'has the expected location-specific values' do
      expect(i[:file_locations_qualified]).to eq [
        { :location => 'reading_rm', :rule => nil }, { :location => 'new_reading_rm', :rule => 'new-rule' },
        { :location => 'reading_rm', :rule => 'no-download' }
      ]
      expect(i[:obj_locations_qualified]).to eq []
      expect(i[:file_locations]).to eq ['reading_rm', 'new_reading_rm']
      expect(i[:obj_locations]).to eq []
    end

    it 'has the expected agent-specific values' do
      expect(i[:file_agents_qualified]).to eq [
        { :agent => 'someapp1', :rule => nil }, { :agent => 'someapp2', :rule => 'somerule' }
      ]
      expect(i[:obj_agents_qualified]).to eq [{ :agent => 'adminapp', :rule => 'objlevel' }]
      expect(i[:file_agents]).to eq ['someapp1', 'someapp2']
      expect(i[:obj_agents]).to eq ['adminapp']
    end

    it 'has the expected group-specific values' do
      # stanford's the only group we specifically parse out for rights logic or
      # indexing, so we don't expect "other" to show up in index_elements, even
      # though it's in the XML.
      expect(i[:file_groups_qualified]).to eq [
        { :group => 'stanford', :rule => nil }, { :group => 'stanford', :rule => 'no-download' }
      ]
      expect(i[:obj_groups_qualified]).to eq []
      expect(i[:file_groups]).to eq ['stanford']
      expect(i[:obj_groups]).to eq []
    end
  end

end
