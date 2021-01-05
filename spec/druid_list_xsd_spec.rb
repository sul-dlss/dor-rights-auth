# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

describe 'XSD with <include> subcomponent' do
  describe 'validate' do

    path = File.expand_path(File.dirname(__FILE__) + '/../lib/dor/xsd/druidlist.xsd')
    druidlist = Nokogiri::XML::Schema(File.open(path))

    it 'succeeds for conformant data' do
      xmlblock = <<~'EOXML'
        <druidlist>
        <druid>vh098ff0657</druid>
        <druid>tp736tw2065</druid>
        <druid>qm691hk9133</druid>
        <druid>dy555zk9425</druid>
        <druid>td692bt6464</druid>
        <druid>kj269pw9870</druid>
        <druid>tf943ng9312</druid>
        <druid>hh193pj0046</druid>
        <druid>wj852rz5419  </druid>
        <druid> wf879xg3194</druid>
        <druid>
            sf031xg8376
        </druid>
        </druidlist>
      EOXML
      xml = Nokogiri::XML(xmlblock)
      expect(druidlist).to be
      expect(xml).to be
      errors = []
      druidlist.validate(xml).each do |error|
        errors.push error.message
        puts error.message
      end
      expect(errors).to eq []
    end

    {
      'tp736tw205' => 'too short',
      'dy555zk94255' => 'too long',
      'tf943n!9312' => 'illegal character',
      'wj852r5z419' => 'wrong positions',
      'wj852 5z419' => 'internal whitespace'
    }.each { |k, v|
      it "catches bad value (#{v})" do
        xmlblock = "<druidlist><druid>#{k}</druid></druidlist>"
        druidlist = Nokogiri::XML::Schema(File.open(path))
        xml = Nokogiri::XML(xmlblock)
        expect(druidlist).to be
        expect(xml).to be
        errors = []
        druidlist.validate(xml).each do |error|
          errors.push error.message
        end
        expect(errors.size).to eq 1
      end
    }

  end
end
