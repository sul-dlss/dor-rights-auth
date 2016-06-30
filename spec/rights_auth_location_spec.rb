require 'spec_helper'

describe Dor::RightsAuth do

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
        # see (https://consul.stanford.edu/display/chimera/Rights+metadata+--+the+rightsMetadata+datastream)
        #   for more information
        context 'multiple <access> elements (NOT kosher - documenting current behavior)' do
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
        context 'single <access>, multiple <machine> elements (preferred way)' do
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
        context 'single <access>, single <machine> element (NOT kosher - documenting current behavior)' do
          # this *may* be how we do "AND" in the future (distinguish it from "OR")
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
        # see (https://consul.stanford.edu/display/chimera/Rights+metadata+--+the+rightsMetadata+datastream)
        #   for more information
        context 'multiple <access> elements (NOT kosher - documenting current behavior)' do
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
        context 'single <access>, multiple <machine> elements (preferred way)' do
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
        context 'single <access>, single <machine> element (NOT kosher - documenting current behavior)' do
          # this *may* be how we do "AND" in the future (distinguish it from "OR")
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
end
