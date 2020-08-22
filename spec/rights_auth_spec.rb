# frozen_string_literal: true

require 'spec_helper'

describe Dor::RightsAuth do
  let(:world_readable_xml) do
    <<-EOXML
      <rightsMetadata>
        <access type="read">
          <machine>
            <world />
          </machine>
        </access>
      </rightsMetadata>
    EOXML
  end
  let(:stanford_readable_xml) do
    <<-EOXML
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
      r1 = Dor::RightsAuth.parse stanford_readable_xml
      r2 = Dor::RightsAuth.parse "<some><other><junk>#{stanford_readable_xml}</junk></other></some>"
      r3 = Dor::RightsAuth.parse Nokogiri::XML(stanford_readable_xml)
      [r1, r2, r3].each { |r|
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
      r = Dor::RightsAuth.parse world_readable_xml
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
      expect(r).not_to be_stanford_only_unrestricted
    end

    context 'file level' do
      context 'stanford-only access but object-level world access' do
        context 'multiple <file> elements inside single <access> element' do
          it 'false' do
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

        context 'each <file> element inside own <access> element' do
          it 'false' do
            xml = <<-EOXML
              <rightsMetadata>
                <access type="read">
                  <file>interviews1.doc</file>
                  <machine>
                    <group>stanford</group>
                  </machine>
                </access>
                <access type="read">
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
      end
    end
  end

  describe '#stanford_only_downloadable?' do
    it 'false if object has stanford-only read access with no-download rule' do
      rights_md_xml = <<-EOXML
        <rightsMetadata>
          <access type="read">
            <machine>
              <group rule="no-download">stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      EOXML
      r = Dor::RightsAuth.parse rights_md_xml
      expect(r).not_to be_stanford_only_downloadable
      expect(r).not_to be_public_downloadable
    end

    it 'true if object has stanford-only read access without a rule attribute' do
      r = Dor::RightsAuth.parse stanford_readable_xml
      expect(r).to be_stanford_only_downloadable
      expect(r).not_to be_public_downloadable
    end

    it 'true if object has stanford-only read access with rule other than no-download' do
      rights_md_xml = <<-EOXML
        <rightsMetadata>
          <access type="read">
            <machine>
              <group rule="foobar">stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      EOXML
      r = Dor::RightsAuth.parse rights_md_xml
      expect(r).to be_stanford_only_downloadable
      expect(r).not_to be_public_downloadable
    end

    it 'false if the object does not have stanford-only read access' do
      r = Dor::RightsAuth.parse world_readable_xml
      expect(r).not_to be_stanford_only_downloadable
      expect(r).to be_public_downloadable
    end

    context 'file level' do
      context 'stanford-only access but object-level world access' do
        context 'multiple <file> elements inside single <access> element' do
          it 'false' do
            xml = <<-EOXML
              <rightsMetadata>
                <access type="read">
                  <file>interviews1.doc</file>
                  <file>interviews2.doc</file>
                  <machine>
                    <group rule='no-download' >stanford</group>
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
            expect(rights).not_to be_stanford_only_downloadable
          end
        end

        context 'each <file> element inside own <access> element' do
          it 'false' do
            xml = <<-EOXML
              <rightsMetadata>
                <access type="read">
                  <file>interviews1.doc</file>
                  <machine>
                    <group rule='no-download'>stanford</group>
                  </machine>
                </access>
                <access type="read">
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
            expect(rights).not_to be_stanford_only_downloadable
          end
        end
      end
    end
  end

  describe '#public_unrestricted?' do

    it 'true if object has world readable visibility' do
      r = Dor::RightsAuth.parse world_readable_xml
      expect(r).to be_public_unrestricted
    end

    it 'false if there is no machine readable world visibility' do
      r = Dor::RightsAuth.parse stanford_readable_xml
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

    it 'false when there is file-level world access but object-level stanford-only access' do
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

  describe '#public_downloadable?' do
    it 'false if object has world read access with no-download rule' do
      rights = <<-EOXML
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world rule='no-download' />
            </machine>
          </access>
        </rightsMetadata>
      EOXML
      r = Dor::RightsAuth.parse rights
      expect(r).not_to be_public_downloadable
    end

    it 'true if object has world read access without a rule attribute' do
      r = Dor::RightsAuth.parse world_readable_xml
      expect(r).to be_public_downloadable
    end

    it 'true if object has world read access with rule other than no-download' do
      rights = <<-EOXML
        <rightsMetadata>
          <access type="read">
            <machine>
              <world rule='foobar' />
            </machine>
          </access>
        </rightsMetadata>
      EOXML
      r = Dor::RightsAuth.parse rights
      expect(r).to be_public_downloadable
    end

    it 'false if file-level world downloadable access but object-level stanford-only non-downloadable' do
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
              <group rule="no-download">stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      EOXML
      r = Dor::RightsAuth.parse rights
      expect(r).not_to be_public_downloadable
    end
  end

  describe '#readable?' do
    it 'true if the rights metadata contains a read block' do
      r = Dor::RightsAuth.parse world_readable_xml
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

  shared_examples 'citation only scenarios' do
    describe 'parse' do
      it 'correctly answers various rights queries where possible, and raises when it is unable' do
        r = Dor::RightsAuth.parse rights

        world, rule1 = r.world_rights
        stan,  rule2 = r.stanford_only_rights
        expect(world).not_to be
        expect(stan ).not_to be
        expect(rule1).to be_nil
        expect(rule2).to be_nil
        expect(r).not_to be_readable
        expect(r).not_to be_public_unrestricted
        expect { r.citation_only? }.to raise_error(RuntimeError)
      end
    end

    describe 'parse for indexing' do
      it 'correctly answers various rights queries' do
        r = Dor::RightsAuth.parse rights, true

        world, rule1 = r.world_rights
        stan,  rule2 = r.stanford_only_rights
        expect(world).not_to be
        expect(stan ).not_to be
        expect(rule1).to be_nil
        expect(rule2).to be_nil
        expect(r).not_to be_readable
        expect(r).not_to be_public_unrestricted
        expect(r.citation_only?).to be true
      end
    end
  end

  describe 'rights metadata indicates world discoverability, but has no read block' do
    it_behaves_like 'citation only scenarios' do
      let(:rights) do
        <<-EOXML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
          </rightsMetadata>
        EOXML
      end
    end
  end

  describe 'rights metadata indicates world discoverability, but read access is explicitly none' do
    it_behaves_like 'citation only scenarios' do
      let(:rights) do
        <<-EOXML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <none/>
              </machine>
            </access>
          </rightsMetadata>
        EOXML
      end
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
        expect { r.dark? }.to raise_error(RuntimeError)
      end
    end

    describe 'parse for indexing' do
      it 'correctly' do
        r = Dor::RightsAuth.parse rights, true

        world, rule1 = r.world_rights
        stan,  rule2 = r.stanford_only_rights
        expect(world).not_to be
        expect(stan ).not_to be
        expect(rule1).to be_nil
        expect(rule2).to be_nil
        expect(r).not_to be_readable
        expect(r).not_to be_public_unrestricted_file('file.doc')
        expect(r).not_to be_public_unrestricted
        expect(r.dark?).to be true
      end
    end
  end

  describe 'explicit none' do
    it_behaves_like 'dark scenarios' do
      let(:rights) { <<-EOXML
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
      let(:rights) { <<-EOXML
          <rightsMetadata>
          </rightsMetadata>
      EOXML
      }
    end
  end

  describe 'empty access' do
    it_behaves_like 'dark scenarios' do
      let(:rights) { <<-EOXML
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
      let(:rights) { <<-EOXML
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
      r = Dor::RightsAuth.parse world_readable_xml
      expect(r.allowed_read_agent?('another-app-name')).not_to be
    end

  end

  describe '#stanford_only_unrestricted_file?' do
    let(:dra) do
      Dor::RightsAuth.parse <<-EOXML
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
    end

    it 'true if a file has stanford-only read access' do
      expect(dra).to be_stanford_only_unrestricted_file('interviews1.doc')
      expect(dra).to be_stanford_only_unrestricted_file('interviews2.doc')
    end

    it 'value of object level #stanford_only_unrestricted? if the queried file is not listed' do
      expect(dra).not_to be_stanford_only_unrestricted_file('object-level-rights.xml')
      expect(dra.stanford_only_unrestricted_file?('object-level-rights.xml')).to eq dra.stanford_only_unrestricted?
    end

    it 'false if a file is stanford-only AND has a rule attribute' do
      expect(dra).not_to be_stanford_only_unrestricted_file('su-only-no-download.doc')
    end
  end

  describe '#stanford_only_downloadable_file?' do
    let(:dra) do
      Dor::RightsAuth.parse <<-EOXML
        <rightsMetadata>
          <access type="read">
            <file>no-download1.doc</file>
            <machine>
              <group rule="no-download">stanford</group>
            </machine>
          </access>
          <access type="read">
            <file>download-ok.pdf</file>
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
    end

    it 'true if file is stanford only downloadable' do
      expect(dra).to be_stanford_only_downloadable_file('download-ok.pdf')
    end

    it 'false if file not stanford only downloadable?' do
      expect(dra).not_to be_stanford_only_downloadable_file('no-download1.doc')
    end

    it 'value of object level #downloadable? if the queried file is not listed' do
      expect(dra).not_to be_stanford_only_downloadable_file('file_w_object_level_rights')
      expect(dra.stanford_only_downloadable_file?('file_w_object_level_rights')).to eq dra.stanford_only_downloadable?
    end
  end

  describe '#public_unrestricted_file?' do
    context 'stanford-only object level read-access, but world access to individual files' do
      let(:dra) do
        Dor::RightsAuth.parse <<-EOXML
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
      end

      it 'true if the file has world unrestricted read access' do
        expect(dra).to be_public_unrestricted_file('interviews2.doc')
      end

      it 'value of object level #public? if the queried file is not listed' do
        expect(dra).not_to be_public_unrestricted_file('stanford-only-file.txt')
      end
    end
  end

  describe '#public_downloadable_file?' do
    context 'stanford-only object level read-access, but world access to individual files' do
      let(:dra) do
        Dor::RightsAuth.parse <<-EOXML
          <rightsMetadata>
            <access type="read">
              <file>no-download1.doc</file>
              <machine>
                <world rule="no-download"/>
              </machine>
            </access>
            <access type="read">
              <file>download-ok.pdf</file>
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        EOXML
      end

      it 'true if file is downloadable' do
        expect(dra).to be_public_downloadable_file('download-ok.pdf')
      end

      it 'false if file not downloadable?' do
        expect(dra).not_to be_public_downloadable_file('no-download1.doc')
      end

      it 'value of object level #downloadable? if the queried file is not listed' do
        expect(dra).not_to be_public_downloadable_file('file_w_object_level_rights')
        expect(dra.public_downloadable_file?('file_w_object_level_rights')).to eq dra.public_downloadable?
      end
    end
  end

end
