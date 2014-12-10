require 'nokogiri'
require 'time'

# We handle the ugly stuff, so you don't have to.

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

    CONTAINS_STANFORD_XPATH = "contains(translate(text(), 'STANFORD', 'stanford'), 'stanford')"

    attr_accessor :obj_lvl, :file, :embargoed, :index_elements

    # note: index_elements is only valid for the xml as parsed, not after subsequent manipulation

    def initialize
      @file = {}
      @index_elements = {}
    end

    # Returns true if the object is under embargo.
    # @return [Boolean]
    def embargoed?
      @embargoed
    end

    # Returns true if the object is world readable AND has no rule attribute
    # @return [Boolean]
    def world_unrestricted?
      @obj_lvl.world.value && @obj_lvl.world.rule.nil?
    end

    alias_method :public_unrestricted?, :world_unrestricted?

    def readable?
      public_unrestricted? || stanford_only_unrestricted? # TODO stanford_only or public with rule, figure out if this is still a legit method
    end

    # Returns true if the object is stanford-only readable AND has no rule attribute
    # @return [Boolean]
    def stanford_only_unrestricted?
      @obj_lvl.group[:stanford].value && @obj_lvl.group[:stanford].rule.nil?
    end

    # Returns true if the passed in agent (usually an application) is allowed access to the object without a rule
    # @param [String] agent_name Name of the agent that wants to access this object
    # @return [Boolean]
    def agent_unrestricted?(agent_name)
      return false unless @obj_lvl.agent.has_key? agent_name
      @obj_lvl.agent[agent_name].value && @obj_lvl.agent[agent_name].rule.nil?
    end

    alias_method :allowed_read_agent?, :agent_unrestricted?

    # Returns true if the file is stanford-only readable AND has no rule attribute
    #   If rights do not exist for this file, then object level rights are returned
    # @see #stanford_only_unrestricted?
    # @param [String] file_name Name of the file that is tested for stanford_only rights
    # @return [Boolean]
    def stanford_only_unrestricted_file?(file_name)
      return stanford_only_unrestricted? if( @file[file_name].nil? || @file[file_name].group[:stanford].nil? )

      @file[file_name].group[:stanford].value && @file[file_name].group[:stanford].rule.nil?
    end

    # Returns true if the file is world readable AND has no rule attribute
    #   If world rights do not exist for this file, then object level rights are returned
    # @see #world_unrestricted?
    # @param [String] file_name Name of file that is tested for world rights
    # @return [Boolean]
    def world_unrestricted_file?(file_name)
      return world_unrestricted? if( @file[file_name].nil? || @file[file_name].world.nil? )

      @file[file_name].world.value && @file[file_name].world.rule.nil?
    end

    alias_method :public_unrestricted_file?, :world_unrestricted_file?

    # Returns whether an object-level world node exists, and the value of its rule attribute
    # @return [Array<(Boolean, String)>] First value: existance of node. Second Value: rule attribute, nil otherwise
    # @example Using multiple variable assignment to read both array elements
    #   world_exists, world_rule = rights.world_rights
    def world_rights
      [@obj_lvl.world.value, @obj_lvl.world.rule]
    end

    # Returns whether and object-level group/stanford node exists, and the value of its rule attribute
    # @return (see #world_rights)
    # @example Using multiple variable assignment to read both array elements
    #   su_only_exists, su_only_rule = rights.stanford_only_rights
    def stanford_only_rights
      [@obj_lvl.group[:stanford].value, @obj_lvl.group[:stanford].rule]
    end

    # Returns whether an object-level agent node exists for the passed in agent, and the value of its rule attribute
    # @param [String] agent_name name of the app or thing that is tested for access
    # @return (see #world_rights)
    # @example Using multiple variable assignment to read both array elements
    #   agent_exists, agent_rule = rights.agent_rights('someapp')
    # @note should be called after doing a check for world_unrestricted?
    def agent_rights(agent_name)
      return [false, nil] if(@obj_lvl.agent[agent_name].nil?)
      [@obj_lvl.agent[agent_name].value, @obj_lvl.agent[agent_name].rule]
    end

    # Returns whether a file-level world node exists, and the value of its rule attribute
    #  If a world node does not exist for this file, then object-level world rights are returned
    # @see #world_rights
    # @param [String] file_name name of the file
    # @return (see #world_rights)
    # @example Using multiple variable assignment to read both array elements
    #   world_exists, world_rule = rights.world_rights_for_file('somefile')
    def world_rights_for_file(file_name)
      return world_rights if( @file[file_name].nil? || @file[file_name].world.nil? )

      [@file[file_name].world.value, @file[file_name].world.rule]
    end

    # Returns whether a file-level group/stanford node exists, and the value of its rule attribute
    #    If a group/stanford node does not exist for this file, then object-level group/stanford rights are returned
    # @see #stanford_only_rights
    # @param (see #world_rights_for_file)
    # @return (see #world_rights)
    # @example Using multiple variable assignment to read both array elements
    #   su_only_exists, su_only_rule = rights.stanford_only_rights_for_file('somefile')
    def stanford_only_rights_for_file(file_name)
      return stanford_only_rights if( @file[file_name].nil? || @file[file_name].group[:stanford].nil?)

      [@file[file_name].group[:stanford].value, @file[file_name].group[:stanford].rule]
    end

    # Returns whether a file-level agent-node exists, and the value of its rule attribute
    #    If an agent-node does not exist for this file, then object-level agent rights are returned
    # @param [String] file_name name of the file being tested
    # @param [String] agent_name name of the agent being tested
    # @return (see #world_rights)
    # @example Using multiple variable assignment to read both array elements
    #   agent_exists, agent_rule = rights.agent_rights_for_file('filex', 'someapp')
    def agent_rights_for_file(file_name, agent_name)
      return agent_rights(agent_name) if( @file[file_name].nil?) # look at object level agent rights if the file-name is not stored

      return [false, nil] if( @file[file_name].agent[agent_name].nil?) # file rules exist, but not for this agent

      [@file[file_name].agent[agent_name].value, @file[file_name].agent[agent_name].rule]
    end

    # Check formedness of rightsMetadata -- to be replaced with XSD once formalized, one fine day
    # @param [Nokogiri::XML] the rightsMetadata document
    # @return [Array]        list of things that are wrong with it
    def RightsAuth.validate_lite(doc)
      if (doc.nil? || doc.at_xpath("//rightsMetadata").nil?)
          return ["no_rightsMetadata"]
      end
      errors = []
      maindiscover = doc.at_xpath("//rightsMetadata/access[@type='discover' and not(file)]")
      mainread     = doc.at_xpath("//rightsMetadata/access[@type='read'     and not(file)]")

      if maindiscover.nil?
        errors.push "no_discover_access", "no_discover_machine"
      elsif maindiscover.at_xpath("./machine").nil?
        errors.push "no_discover_machine"
      elsif (maindiscover.at_xpath("./machine/world[not(@rule)]").nil? && maindiscover.at_xpath("./machine/none").nil?)
        errors.push "discover_machine_unrecognized"
      end
      if mainread.nil?
        errors.push "no_read_access", "no_read_machine"
      elsif mainread.at_xpath("./machine").nil?
        errors.push "no_read_machine"
      else
        ## TODO: deeper read validation?
      end

      errors
    end

    # Assemble various characterizing terms for index from XML
    # @param [Nokogiri::XML] the rightsMetadata document
    # @return [Array] Strings of interest to the Solr index
    def RightsAuth.extract_index_terms(doc)
      terms = []
      machine = doc.at_xpath("//rightsMetadata/access[@type='read' and not(file)]/machine")
      terms.push  "none_discover" if doc.at_xpath("//rightsMetadata/access[@type='discover']/machine/none")
      terms.push "world_discover" if doc.at_xpath("//rightsMetadata/access[@type='discover']/machine/world[not(@rule)]")
      return terms if machine.nil?

      terms.push "has_group_rights" if machine.at_xpath("./group")
      terms.push "has_rule" if machine.at_xpath(".//@rule")

      if (machine.at_xpath("./group[not(@rule) and #{CONTAINS_STANFORD_XPATH}]"))
        terms.push "group|stanford"
      elsif (machine.at_xpath("./group[@rule and #{CONTAINS_STANFORD_XPATH}]"))
        terms.push "group|stanford_with_rule"
      elsif (machine.at_xpath("./group"))
        terms.push "group|#{machine.at_xpath("./group").value.downcase}"
      end

      if (machine.at_xpath("./none"))
        terms.push "none_read"
      elsif (machine.at_xpath("./world[not(@rule)]"))
        terms.push "world_read"
      elsif (machine.at_xpath("./world/@rule"))
        terms.push "world|#{machine.at_xpath("./world/@rule").value.downcase}"
      end

      # now some statistical generation
      names = machine.element_children.collect { |node| node.name }
      kidcount = names.each_with_object(Hash.new(0)){ |word,counts| counts[word] += 1 }
      countphrase = kidcount.sort.collect{|k,v| "#{k}#{v}"}.join("|")
      terms.push "profile:" + countphrase unless countphrase.empty?

      filemachines = doc.xpath("//rightsMetadata/access[@type='read' and file]/machine")
      unless filemachines.empty?
        terms.push "has_file_rights", "file_rights_count|#{filemachines.count}"
        counts = Hash.new(0)
        filemachines.each { |filemachine|
          filemachine.element_children.each { |node|
            counts[node.name] += 1
          }
        }
        counts.each { |k,v|
          terms.push "file_has_#{k}", "file_rights_for_#{k}|#{v}"
        }
      end

      terms
    end

    # Give the index what it needs
    # @param [Nokogiri::XML] the rightsMetadata document
    # @return [Hash] Strings of interest to the Solr index, including:
    # {
    #   :primary => '...',   # string of foremost rights category, if determinable
    #   :errors  => [...],   # known error cases
    #   :terms   => [...]    # array of non-error characterizations and stats strings
    # }
    def RightsAuth.extract_access_rights(doc)
      errors = validate_lite(doc)
      stuff = {
        :primary => nil,
        :errors  => errors,
        :terms   => []
      }

      if (errors.include? "no_rightsMetadata")
        stuff[:primary] = 'dark'
        return stuff    # short circuit if no metadata -- no point going on
      end

      stuff[:terms] = extract_index_terms(doc)

      if (stuff[:terms].include?("none_discover"))
        stuff[:primary] = 'dark'
      elsif (errors.include?("no_discover_access") || errors.include?("no_discover_machine"))
        stuff[:primary] = 'dark'
      elsif (errors.include?("no_read_machine") || stuff[:terms].include?("none_read"))
        stuff[:primary] = 'citation'
      elsif (stuff[:terms].include? "world_read")
        stuff[:primary] = 'world'
      elsif (stuff[:terms].include? "group|stanford")
        stuff[:primary] = 'stanford'
      elsif (stuff[:terms].include? "has_rule")
        stuff[:primary] = 'complicated'
      end
      stuff
    end


    # Create a Dor::RightsAuth object from xml
    # @param [String] xml rightsMetadata xml that will be parsed to build a RightsAuth object
    # @return Dor::RightsAuth created after parsing rightsMetadata xml
    def RightsAuth.parse(xml, forindex=false)
      rights = Dor::RightsAuth.new
      rights.obj_lvl = EntityRights.new
      rights.obj_lvl.world = Rights.new

      doc = Nokogiri::XML(xml)
      if(doc.at_xpath("//rightsMetadata/access[@type='read' and not(file)]/machine/world"))
        rights.obj_lvl.world.value = true
        rule = doc.at_xpath("//rightsMetadata/access[@type='read' and not(file)]/machine/world/@rule")
        rights.obj_lvl.world.rule = rule.value if(rule)
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

      if (forindex)
        rights.index_elements = extract_access_rights(doc)
      end

      if(doc.at_xpath("//rightsMetadata/access[@type='read' and not(file)]/machine/group[#{CONTAINS_STANFORD_XPATH}]"))
        rights.obj_lvl.group[:stanford].value = true
        rule = doc.at_xpath("//rightsMetadata/access[@type='read' and not(file)]/machine/group[#{CONTAINS_STANFORD_XPATH}]/@rule")
        rights.obj_lvl.group[:stanford].rule = rule.value if(rule)
      else
        rights.obj_lvl.group[:stanford].value = false
      end

      rights.obj_lvl.agent = {}
      doc.xpath("//rightsMetadata/access[@type='read' and not(file)]/machine/agent").each do |node|
        r = Rights.new
        r.value = true
        r.rule = node['rule']
        rights.obj_lvl.agent[node.content] = r
      end

      # Initialze embargo_status to false
      rights.embargoed = false
      embargo_node = doc.at_xpath("//rightsMetadata/access[@type='read']/machine/embargoReleaseDate")
      if(embargo_node)
        embargo_dt = Time.parse(embargo_node.content)
        rights.embargoed = true if(embargo_dt > Time.now)
      end

      access_with_files = doc.xpath("//rightsMetadata/access[@type='read' and file]")
      access_with_files.each do |access_node|
        stanford_access = Rights.new
        world_access    = Rights.new
        if access_node.at_xpath("machine/group[#{CONTAINS_STANFORD_XPATH}]")
          stanford_access.value = true
          rule = access_node.at_xpath("machine/group[#{CONTAINS_STANFORD_XPATH}]/@rule")
          stanford_access.rule = rule.value if (rule)
        else
          stanford_access.value = false
        end

        if access_node.at_xpath("machine/world")
          world_access.value = true
          rule = access_node.at_xpath("machine/world/@rule")
          world_access.rule = rule.value if (rule)
        else
          world_access.value = false
        end

        file_agents = {}
        access_node.xpath("machine/agent").each do |node|
          r = Rights.new
          r.value = true
          r.rule = node['rule']
          file_agents[node.content] = r
        end

        access_node.xpath('file').each do |f|
          file_rights = EntityRights.new
          file_rights.world = world_access
          file_rights.group = { :stanford => stanford_access }
          file_rights.agent = file_agents

          rights.file[f.content] = file_rights
        end
      end

      rights
    end

  end
end

