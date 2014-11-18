require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'nokogiri'

describe "XSD with subcomponent" do
  describe "validate" do

    ['rights_basics', 'rights_types', 'humanlist'].each { |f|
      path = File.expand_path(File.dirname(__FILE__) + "/../lib/dor/#{f}.xsd")
      it "XSD syntax for #{f}.xsd" do
        schema = Nokogiri::XML::Schema(File.open(path))
        expect(schema).to be
      end
    }

    path = File.expand_path(File.dirname(__FILE__) + '/../lib/dor/rights_types.xsd')
#   schema = Nokogiri::XML::Schema(File.open(path))

#   it "human" do
#     xmlblock =<<-'EOXML'
#     <human>This document is available only to the Stanford faculty, staff and student community</human>
#     EOXML
#     xml = Nokogiri::XML(xmlblock)
#     expect(schema).to be
#     expect(xml).to be
#     errors = []
#     schema.validate(xml).each do |error|
#       errors.push error.message
#       puts error.message
#     end
#     expect(errors).to eq []
#   end

#   {
#       'tp736tw205'   => 'too short',
#   }.each { |k,v|
#       it "catches bad value (#{v})" do
#         xmlblock = "<druidlist><druid>#{k}</druid></druidlist>"
#         schema = Nokogiri::XML::Schema(File.open(path))
#         xml = Nokogiri::XML(xmlblock)
#         expect(schema).to be
#         expect(xml).to be
#         errors = []
#         schema.validate(xml).each do |error|
#           errors.push error.message
#           # puts error.message
#         end
#         expect(errors.size).to eq 2
#       end
#   }

  end
end
