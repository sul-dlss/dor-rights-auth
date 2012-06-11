require 'nokogiri'
#require 'helpers/cacheable'

module Dor
  # The Individual Right 
  Rights = Struct.new(:value, :rule)

  # Rights for an object or File
  EntityRights = Struct.new(:world, :group, :agent)
  # class EntityRights
  #   @world = #Rights
  #   @group {
  #     :stanford => #Rights
  #   }
  #   @agent {
  #     'app1' => #Rights,
  #     'app2' => #Rights
  #   }
  # end

  # class Dor::RightsAuth
  #   @object_level = # EntityRights
  #   @file {
  #     'file1' => EntityRights,
  #     'file2' => EntityRights
  #   }
  # end

  class RightsAuth
  
    #extend Cacheable
  
    attr_accessor :obj_lvl, :file
  
    def initialize
      @file = {}
    end
    
    def public?
      @obj_lvl.world.value
    end
  
    alias_method :world?, :public?
  
    def readable?
      public? || stanford_only_unrestricted? # TODO stanford_only or public with rule, figure out if this is still a legit method
    end
  
    def stanford_only_unrestricted?
      @obj_lvl.group[:stanford].value && @obj_lvl.group[:stanford].rule.nil?
    end
    
    def allowed_read_agent?(agent_name)
      @obj_lvl.agent.has_key? agent_name
    end
  
    def stanford_only_file?(file_name)
      return stanford_only_unrestricted? if( @file[file_name].nil? || @file[file_name].group[:stanford].nil? )
    
      @file[file_name].group[:stanford].value
    end
  
    def public_file?(file_name)
      return public? if( @file[file_name].nil? || @file[file_name].world.nil? )
    
      @file[file_name].world.value
    end
  
    alias_method :world_file?, :public_file?
  
    # def RightsAuth.find(obj_id)
    #   obj_id =~ /^druid:(.*)$/
    # 
    #   cache_id = "RightsAuth-#{$1}"
    #   self.fetch_from_cache_or_service(cache_id) { self.fetch_and_build($1) }
    # rescue RestClient::Exception => rce
    #   LyberCore::Log.exception rce
    #   nil
    # end
  
    # Fetch the rightsMetadata xml from the RightsMD service
    # Parse the xml and create a Dor::RightsAuth object
    #
    # @param [String] no_ns_druid A druid without the 'druid' namespace prefix
    # @return Dor::RightsAuth created after parsing rightsMetadata xml
    def RightsAuth.parse(xml)
      doc = Nokogiri::XML(xml)
    
      rights = Dor::RightsAuth.new
      rights.obj_lvl = EntityRights.new
      rights.obj_lvl.world = Rights.new
    
      if(doc.at_xpath("//rightsMetadata/access[@type='read' and not(file)]/machine/world"))
        rights.obj_lvl.world.value = true
        # rule = doc.at_xpath("//rightsMetadata/access[@type='read' and not(file)]/machine/world/@rule")
        # rights.obj_lvl.world.
      else
       rights.obj_lvl.world.value = false
      end

      # TODO do we still need this??????    
      # if(doc.at_xpath("//rightsMetadata/access[@type='read' and not(file)]"))
      #   rights[:readable] = true
      # else
      #   rights[:readable] = false
      # end
    
      rights.obj_lvl.group = { :stanford => Rights.new }
    
      if(doc.at_xpath("//rightsMetadata/access[@type='read' and not(file)]/machine/group[text() = 'stanford']"))
        rights.obj_lvl.group[:stanford].value = true
        rule = doc.at_xpath("//rightsMetadata/access[@type='read' and not(file)]/machine/group[text() = 'stanford']/@rule")
        rights.obj_lvl.group[:stanford].rule = rule.value if(rule)
      else
        rights.obj_lvl.group[:stanford].value = false
      end

      rights.obj_lvl.agent = {}
      doc.xpath("//rightsMetadata/access[@type='read']/machine/agent").each do |node|
        r = Rights.new
        r.value = true
        rights.obj_lvl.agent[node.content] = r
      end
        
      access_with_files = doc.xpath( "//rightsMetadata/access[@type='read' and file]")
      access_with_files.each do |access_node|
        stanford_access = Rights.new  
        world_access = Rights.new
        # TODO parse out @rule too
        if access_node.at_xpath("machine/group[text()='stanford']")
          stanford_access.value = true
        else
          stanford_access.value = false
        end
      
        if access_node.at_xpath("machine/world")
          world_access.value = true
        else
          world_access.value = false
        end
      
        access_node.xpath('file').each do |f|
          file_rights = EntityRights.new
          file_rights.world = world_access
          file_rights.group = { :stanford => stanford_access }
          # TODO agent rights for this file
          file_rights.agent = {}
          rights.file[f.content] = file_rights
        end
      end
    
      rights
    end
    
  end
end

