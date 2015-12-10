require 'spec_helper'

describe Dor::RightsAuth do
  it 'handles fixture druid:oo201oo0001' do
    xml = <<-EOXML
    <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
         <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
         <machine>
           <world/>
         </machine>
        </access>
        <access type="read">
         <machine>
         <group>Stanford</group>
         </machine>
        </access>
        <use>
         <human type="creativecommons">Attribution Share Alike license</human>
         <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
    EOXML

    r = Dor::RightsAuth.parse(xml, true)
    expect(r).to be_stanford_only_unrestricted
    expect(r).not_to be_public_unrestricted
    expect(r.index_elements).to include :primary => 'stanford'
  end
end
