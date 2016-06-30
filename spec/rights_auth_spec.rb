require 'spec_helper'

describe Dor::RightsAuth do
  before(:all) do
    @world_xml = <<-EOXML
      <rightsMetadata>
        <access type="read">
          <machine>
            <world />
          </machine>
        </access>
      </rightsMetadata>
    EOXML
    @stanford_xml = <<-EOXML
      <rightsMetadata>
        <access type="read">
          <machine>
            <group>stanford</group>
          </machine>
        </access>
      </rightsMetadata>
    EOXML
  end

  describe '#stanford_only_unrestricted?' do

    it 'true if the object has stanford-only read access without a rule attribute' do
      r1 = Dor::RightsAuth.parse @stanford_xml
      r2 = Dor::RightsAuth.parse "<some><other><junk>#{@stanford_xml}</junk></other></some>"
      r3 = Dor::RightsAuth.parse Nokogiri::XML(@stanford_xml)
      [r1, r2, r3].each{ |r|
        expect(r).to be_stanford_only_unrestricted
        expect(r).not_to be_public_unrestricted
      }
    end

    it "true if capital S is used for 'Stanford'" do
      rights = <<-EOXML
        <rightsMetadata>
          <access type="read">
            <machine>
              <group>Stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      EOXML

      r = Dor::RightsAuth.parse rights
      expect(r).to be_stanford_only_unrestricted
      expect(r).not_to be_public_unrestricted
    end

    it 'false if the object does not have stanford-only read access' do
      r = Dor::RightsAuth.parse @world_xml
      expect(r).not_to be_stanford_only_unrestricted
      expect(r).to be_public_unrestricted
    end

    it 'false if the object has stanford-only read access with a rule attribute' do
      rights = <<-EOXML
        <rightsMetadata>
          <access type="read">
            <machine>
              <group rule="no-download">stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      EOXML

      r = Dor::RightsAuth.parse rights
      expect(r).to_not be_stanford_only_unrestricted
    end

    it 'returns false when there is file-level stanford-only access but object-level world access' do
      xml = <<-EOXML
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
      EOXML

      rights = Dor::RightsAuth.parse xml
      expect(rights).not_to be_stanford_only_unrestricted
    end
  end

  describe '#public_unrestricted?' do

    it 'true if this object has world readable visibility' do
      r = Dor::RightsAuth.parse @world_xml
      expect(r).to be_public_unrestricted
    end

    it 'false if there is no machine readable world visibility' do
      r = Dor::RightsAuth.parse @stanford_xml
      expect(r).not_to be_public_unrestricted
    end

    it 'false if there is no machine/world access WITHOUT a rule attribute' do
      rights = <<-EOXML
        <rightsMetadata>
          <access type="read">
            <machine>
              <world rule="no-download" />
            </machine>
          </access>
        </rightsMetadata>
      EOXML

      r = Dor::RightsAuth.parse rights
      expect(r).not_to be_public_unrestricted
    end

    it 'false if the rights metadata does not contain a read block' do
      rights = <<-EOXML
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      EOXML

      r = Dor::RightsAuth.parse rights
      expect(r).not_to be_public_unrestricted
    end

    it 'returns false when there is file-level world access but object-level stanford-only access' do
      rights = <<-EOXML
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
      EOXML

      r = Dor::RightsAuth.parse rights
      expect(r).not_to be_public_unrestricted
    end

  end

  describe '#readable?' do

    it 'true if the rights metadata contains a read block' do
      r = Dor::RightsAuth.parse @world_xml
      expect(r).to be_readable
    end

    it 'false if the rights metadata does not contain a read block' do
      rights = <<-EOXML
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world />
            </machine>
          </access>
        </rightsMetadata>
      EOXML

      r = Dor::RightsAuth.parse rights
      expect(r).not_to be_readable
    end

    it "false if there's only a read access block with files, but no object level read access" do
      rights = <<-EOXML
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
      EOXML

      r = Dor::RightsAuth.parse rights
      expect(r).not_to be_readable
    end

  end

  shared_examples 'dark scenarios' do
    describe 'parse' do
      it 'correctly' do
        r = Dor::RightsAuth.parse rights

        world, rule1 = r.world_rights
        stan,  rule2 = r.stanford_only_rights
        expect(world).not_to be
        expect(stan ).not_to be
        expect(rule1).to be_nil
        expect(rule2).to be_nil
        expect(r).not_to be_readable
        expect(r).not_to be_public_unrestricted_file('file.doc')
        expect(r).not_to be_public_unrestricted
      end
    end
  end

  describe 'explicit none' do
    it_behaves_like 'dark scenarios' do
      let(:rights) {<<-EOXML
        <rightsMetadata>
          <access type="discover">
            <machine>
              <none/>
            </machine>
          </access>
        </rightsMetadata>
      EOXML
      }
    end
  end
  describe 'empty rightsMetadata' do
    it_behaves_like 'dark scenarios' do
      let(:rights) {<<-EOXML
          <rightsMetadata>
          </rightsMetadata>
        EOXML
      }
    end
  end
  describe 'empty access' do
    it_behaves_like 'dark scenarios' do
      let(:rights) {<<-EOXML
        <rightsMetadata>
          <access type="discover">
          </access>
        </rightsMetadata>
      EOXML
      }
    end
  end
  describe 'empty machine' do
    it_behaves_like 'dark scenarios' do
      let(:rights) {<<-EOXML
        <rightsMetadata>
          <access type="discover">
            <machine>
            </machine>
          </access>
        </rightsMetadata>
      EOXML
      }
    end
  end

  describe '#allowed_read_agent?' do
    it 'true if the passed in user is an allowed read agent' do
      rights = <<-EOXML
        <rightsMetadata>
          <access type="read">
            <machine>
              <agent>app-name</agent>
            </machine>
          </access>
        </rightsMetadata>
      EOXML

      r = Dor::RightsAuth.parse rights
      expect(r.allowed_read_agent?('app-name')).to be
    end

    it 'handles more than one agent' do
      rights = <<-EOXML
        <rightsMetadata>
          <access type="read">
            <machine>
              <agent>app-name</agent>
              <agent>app2</agent>
            </machine>
          </access>
        </rightsMetadata>
      EOXML

      r = Dor::RightsAuth.parse rights
      expect(r.allowed_read_agent?('app2')).to be
    end

    it 'false if the passed in user is NOT an allowed read agent' do
      rights = <<-EOXML
        <rightsMetadata>
          <access type="read">
            <machine>
              <agent>app-name</agent>
            </machine>
          </access>
        </rightsMetadata>
      EOXML

      r = Dor::RightsAuth.parse rights
      expect(r.allowed_read_agent?('another-app-name')).not_to be
    end

    it 'false if there is no read agent in rightsMetadata' do
      r = Dor::RightsAuth.parse @world_xml
      expect(r.allowed_read_agent?('another-app-name')).not_to be
    end

  end

  describe 'location based auth' do
    let(:rights) { described_class.parse(rights_xml) }
    context 'object level' do
      let(:rights_xml) do
        <<-XML
          <rightsMetadata>
            <access type="read">
              <machine>
                <location>spec</location>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'true if there is a matching location in the rights metadata' do
        value, rule = rights.location_rights('spec')
        expect(value).to be true
        expect(rule).to be_nil
      end

      it 'false if there is no matching location in the rights metadata' do
        value, rule = rights.location_rights('not-a-real-location')
        expect(value).to be false
        expect(rule).to be_nil
      end

      describe '#restricted_by_location?' do
        it 'true even when the given file has a no location restriction' do
          expect(rights).to be_restricted_by_location('a-doc-that-is-not-there.doc')
        end
      end

      context 'OR stanford' do
        context 'multiple <access> elements' do
          let(:rights_xml) do
            <<-XML
              <rightsMetadata>
                <access type="read">
                  <machine>
                    <group>stanford</group>
                  </machine>
                </access>
                <access type="read">
                  <machine>
                    <location>spec</location>
                  </machine>
                </access>
              </rightsMetadata>
            XML
          end
          it 'returns that the item is stanford restricted' do
            expect(rights).to be_stanford_only_unrestricted
          end
          it 'returns that the item is location restricted' do
            expect(rights).to be_restricted_by_location('spec')
          end
        end
        context 'single <access>, multiple <machine> elements' do
          let(:rights_xml) do
            <<-XML
              <rightsMetadata>
                <access type="read">
                  <machine>
                    <group>stanford</group>
                  </machine>
                  <machine>
                    <location>spec</location>
                  </machine>
                </access>
              </rightsMetadata>
            XML
          end
          it 'returns that the item is stanford restricted' do
            expect(rights).to be_stanford_only_unrestricted
          end
          it 'returns that the item is location restricted' do
            expect(rights).to be_restricted_by_location('spec')
          end
        end
        context 'single <access>, single <machine> element' do
          let(:rights_xml) do
            <<-XML
              <rightsMetadata>
                <access type="read">
                  <machine>
                    <group>stanford</group>
                    <location>spec</location>
                  </machine>
                </access>
              </rightsMetadata>
            XML
          end
          it 'returns that the item is stanford restricted' do
            expect(rights).to be_stanford_only_unrestricted
          end
          it 'returns that the item is location restricted' do
            expect(rights).to be_restricted_by_location('spec')
          end
        end
      end
    end

    context 'file level' do
      let(:rights_xml) do
        <<-XML
          <rightsMetadata>
            <access type="read">
              <file>location-protected.doc</file>
              <machine>
                <location>spec</location>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'true if there is a matching location for the given file in the rights metadata' do
        value, rule = rights.location_rights_for_file('location-protected.doc', 'spec')
        expect(value).to be true
        expect(rule).to be_nil
      end

      it 'false if there is no matching location for the given file in the rights metadata' do
        value, rule = rights.location_rights_for_file('unkown.doc', 'spec')
        expect(value).to be false
        expect(rule).to be_nil
      end

      it 'returns false when there is a matching file but the location does not exist' do
        value, rule = rights.location_rights_for_file('location-protected.doc', 'not-a-real-location')
        expect(value).to be false
        expect(rule).to be_nil
      end

      describe '#restricted_by_location?' do
        it 'true when the given file has a location restriction' do
          expect(rights).to be_restricted_by_location('location-protected.doc')
        end
      end

      context 'OR stanford' do
        context 'multiple <access> elements' do
          let(:rights_xml) do
            <<-XML
              <rightsMetadata>
                <access type="read">
                  <file>location-or-stanford-protected.doc</file>
                  <machine>
                    <group>Stanford</group>
                  </machine>
                </access>
                <access type="read">
                  <file>location-or-stanford-protected.doc</file>
                  <machine>
                    <location>spec</location>
                  </machine>
                </access>
              </rightsMetadata>
            XML
          end
          it 'file is restricted per second access block only' do
            expect(rights).to be_restricted_by_location('location-or-stanford-protected.doc')
            expect(rights).not_to be_stanford_only_unrestricted_file('location-or-stanford-protected.doc')
          end
        end
        context 'single <access>, multiple <machine> elements' do
          let(:rights_xml) do
            <<-XML
              <rightsMetadata>
                <access type="read">
                  <file>location-or-stanford-protected.doc</file>
                  <machine>
                    <group>Stanford</group>
                  </machine>
                  <machine>
                    <location>spec</location>
                  </machine>
                </access>
              </rightsMetadata>
            XML
          end
          it 'file is stanford restricted' do
            expect(rights).to be_stanford_only_unrestricted_file('location-or-stanford-protected.doc')
          end
          it 'file is location restricted' do
            expect(rights).to be_restricted_by_location('location-or-stanford-protected.doc')
          end
        end
        context 'single <access>, single <machine> element' do
          let(:rights_xml) do
            <<-XML
              <rightsMetadata>
                <access type="read">
                  <file>location-or-stanford-protected.doc</file>
                  <machine>
                    <group>Stanford</group>
                    <location>spec</location>
                  </machine>
                </access>
              </rightsMetadata>
            XML
          end
          it 'file is stanford restricted' do
            expect(rights).to be_stanford_only_unrestricted_file('location-or-stanford-protected.doc')
          end
          it 'file is location restricted' do
            expect(rights).to be_restricted_by_location('location-or-stanford-protected.doc')
          end
        end
      end
    end

    context 'rules' do
      let(:rights_xml) do
        <<-XML
          <rightsMetadata>
            <access type="read">
              <machine>
                <location rule='no-download'>spec</location>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'returns the rule attribute as part of the rights' do
        _, rule = rights.location_rights('spec')
        expect(rule).to eq 'no-download'
      end
    end
  end

  describe '#stanford_only_unrestricted_file?' do

    before(:all) do
      rights = <<-EOXML
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
      EOXML

      @r = Dor::RightsAuth.parse rights
    end

    it 'true if a file has stanford-only read access' do
      expect(@r).to be_stanford_only_unrestricted_file('interviews1.doc')
      expect(@r).to be_stanford_only_unrestricted_file('interviews2.doc')
    end

    it 'returns the value of object level #stanford_only_unrestricted? if the queried file is not listed' do
      expect(@r).not_to be_stanford_only_unrestricted_file('object-level-rights.xml')
      expect(@r.stanford_only_unrestricted_file?('object-level-rights.xml')).to eq @r.stanford_only_unrestricted?
    end

    it 'false if a file is stanford-only AND has a rule attribute' do
      expect(@r).not_to be_stanford_only_unrestricted_file('su-only-no-download.doc')
    end
  end

  describe '#public_unrestricted_file?' do

    context 'stanford-only object level read-access, but world access to individual files' do

      before(:all) do
        rights = <<-EOXML
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
        EOXML

        @r = Dor::RightsAuth.parse rights
      end

      it 'true if the file has world unrestricted read access' do
        expect(@r).to be_public_unrestricted_file('interviews2.doc')
      end

      it 'returns the value of object level #public? if the queried file is not listed' do
        expect(@r).not_to be_public_unrestricted_file('stanford-only-file.txt')
      end

    end
  end

end
