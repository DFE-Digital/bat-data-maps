## Types

LogicalObjectPart = Struct.new(:id,:name,:optional?)
LogicalObject = Struct.new(:id,:name,:parts)
LogicalLink = Struct.new(:source_object,:source_part,:target_object)
PhysicalDatabase = Struct.new(:id,:name)
PhysicalSynchronization = Struct.new(:source_db,:target_db,:trigger)
Realisation = Struct.new(:logical_object,:physical_database,:table,:keys)
Actor = Struct.new(:id,:name)
ActorDependency = Struct.new(:using_actor,:used_actor_or_db)

## Object renderers

class LogicalObject
  def render
    puts "\"#{self.id}\" ["
    puts "  shape=record,"
    print "  label = \"{<root> #{self.name}"
    self.parts.each do |part|
      print " |"
      if part.id != nil
        print " <#{part.id}>"
      end
      print " #{part.name}"
      if part.optional?
        print " (optional)"
      end
    end
    puts "}\""
    puts "];"
  end
end

class LogicalLink
  def render
    puts "\"#{self.source_object}\":#{self.source_part} -> \"#{self.target_object}\":root [arrowhead=vee]"
  end
end

class PhysicalDatabase
  def render
    puts "\"#{self.id}\" [shape=oval, label=\"#{self.name}\"]"
  end
end

class PhysicalSynchronization
  def render
    puts "\"#{self.source_db}\" -> \"#{self.target_db}\" [arrowhead = onormal, label=\"#{self.trigger}\"]"
  end
end

class Realisation
  def render
    print "\"#{self.logical_object}\" -> \"#{self.physical_database}\" [arrowhead = curve; style = dotted"
    if self.table != nil
      print "; headlabel=\"#{self.table}\""
    end
    puts "]"
  end
end

class Actor
  def render
    puts "\"#{self.id}\" [shape=box3d, label=\"#{self.name}\"]"
  end
end

class ActorDependency
  def render
    puts "\"#{self.using_actor}\" -> \"#{self.used_actor_or_db}\" [arrowhead = normal]"
  end
end

def render(things)
  things.each do |thing|
    thing.render()
  end
end

## Main map class

class Map
  def initialize()
    @logical_objects = Array.new()
    @logical_links = Array.new()
    @physical_dbs = Array.new()
    @physical_synchs = Array.new()
    @realisations = Array.new()
    @actors = Array.new()
    @actor_dependencies = Array.new()

    @nodes = Hash.new()
  end

  ## Data inserters
  def logical_object(id,name=id,parts=[])
    node = LogicalObject.new(id,name,parts.map do |element|
                               if element.class == String
                                 LogicalObjectPart.new(nil,element,false)
                               elsif element.class == Array
                                 if element.length == 2
                                   LogicalObjectPart.new(element[0],element[1],false)
                                 elsif element.length == 3
                                   LogicalObjectPart.new(*element)
                                 else
                                   raise "Invalid logical object part #{element}"
                                 end
                               else
                                 raise "Invalid logical object part #{element}"
                               end
                             end)
    @logical_objects.push(node)
    @nodes[id] = node
  end

  def logical_link(source_object,source_part,target_object)
    @logical_links.push(LogicalLink.new(source_object,source_part,target_object))
  end

  def physical_database(id,name=id)
    node = PhysicalDatabase.new(id,name)
    @physical_dbs.push(node)
    @nodes[id] = node
  end

  def physical_synch(source_db,target_db,trigger)
    @physical_synchs.push(PhysicalSynchronization.new(source_db,target_db,trigger))
  end

  def realisation(logical_object,physical_database,table=nil,keys=[])
    @realisations.push(Realisation.new(logical_object,physical_database,table,keys))
  end

  def actor(id,name=id)
    node = Actor.new(id,name)
    @actors.push(node)
    @nodes[id] = node
  end

  def actor_uses(actor,actor_or_db)
    @actor_dependencies.push(ActorDependency.new(actor,actor_or_db))
  end

  ## View generators
  def generate_logical_view()
    puts "digraph \"DfE Logical\" {"
    render (@logical_objects)
    render (@logical_links)
    puts "}"
  end

  def generate_physical_view()
    puts "digraph \"DfE Physical\" {"
    render (@physical_dbs)
    render (@physical_synchs)
    puts "}"
  end

  def generate_realisation_view()
    puts "digraph \"DfE Realisations\" {"
    render (@logical_objects)
    render (@physical_dbs)
    render (@realisations)
    puts "}"
  end

  def generate_actors_view()
    puts "digraph \"DfE Actors\" {"
    render (@physical_dbs)
    render (@actors)
    render (@actor_dependencies)
    puts "}"
  end

  def render_key_html(key)
    if key.end_with?("?")
      "<i>#{key[..-2]}</i> <b>(optional)</b>"
    elsif key.end_with?("~")
      "<i>#{key[..-2]}</i> <b>(fuzzy)</b>"
    else
      key
    end
  end

  def generate_realisation_html_view()
    puts "<html>"
    puts "<body>"
    puts "<table border=\"1\">"
    puts "<tr><th>Logical Object</th><th>Physical Database [: Table]</th><th>Key</th></tr>"
    @realisations.sort { |a,b| a.logical_object <=> b.logical_object }.each do |realisation|
      object_name = @nodes[realisation.logical_object].name
      db_name = @nodes[realisation.physical_database].name
      if realisation.table != nil
        if realisation.keys.length == 0
          puts "<tr><td>#{object_name}</td><td>#{db_name} : #{realisation.table}</td><td></td></tr>"
        else
          kr = render_key_html(realisation.keys.first)
          puts "<tr><td rowspan=\"#{realisation.keys.length}\">#{object_name}</td><td rowspan=\"#{realisation.keys.length}\">#{db_name} : #{realisation.table}</td><td>#{kr}</td></tr>"
          realisation.keys[1..].each do |key|
            kr = render_key_html(key)
            puts "<tr><td>#{kr}</td></tr>"
          end
        end
      else
        puts "<tr><td>#{object_name}</td><td>#{db_name}</td><td></td></tr>"
      end
    end
    puts "</table>"
    puts "</body>"
    puts "</html>"
  end

  def generate_all_views()
    old_stdout = $stdout
    
    $stdout = File.new("logical.dot","w")
    generate_logical_view()
    $stdout.close()
    
    $stdout = File.new("physical.dot","w")
    generate_physical_view()
    $stdout.close()
    
    $stdout = File.new("realisations.dot","w")
    generate_realisation_view()
    $stdout.close()
    
    $stdout = File.new("realisations.html","w")
    generate_realisation_html_view()
    $stdout.close()
    
    $stdout = File.new("actors_dbs.dot","w")
    generate_actors_view()
    $stdout.close()

    $stdout = old_stdout
  end
end

## The data

map = Map.new()

# Logical objects, and how they link to each other

# Style guide:

# 1) Don't explicitly represent the storing of history. For instance, we want a
# history of lead school relationships from a provider so we can know who WAS
# the lead school or who is SCHEDULED to be the lead school, but we don't
# explicitly show this in the diagram. However, things like employments that
# have a start/end as well as some other useful properties (such as the role) we
# DO explicitly show, even though their start/end forms a history, as there's
# other imoprtant state to show, or a potential many-to-many relationship (as is
# the case with school experience).

# 2) Avoid cluttering the diagram with technical details: keep it problem-domain
# focused. Omit obvious uninteresting fields (names, etc). Summarise groups of
# fields ("contact details" rather than address1, address2, ...)

# 3) We can skim over some minor problem-domain details, like the fact that
# applications have referees which are also people, if they're not particularly
# interesting; this is a value judgement which should be re-assessed if that
# fact BECOMES interesting later.

# Maybe a "site"? "establishment"? "location"?
map.logical_object("location","Location",[["urn","URN",true]])

map.logical_object("itt-provider","ITT Provider",[["lead","Lead school",false]])
map.logical_link("itt-provider","lead","location")

map.logical_object("accredited-provider","Accredited Provider (HEI/SCITT)",[])

map.logical_object("person","Person",[["trn","TRN",true]])

map.logical_object("employment","Employment",["start / end","role",["employee","Employee",false],["employer","Employer",false]])
map.logical_link("employment","employee","person")
map.logical_link("employment","employer","itt-provider")
map.logical_link("employment","employer","location")

map.logical_object("vacancy","Vacancy",[["employer","Employer"]])
map.logical_link("vacancy","employer","location")

map.logical_object("job-application","Job application",[["applicant","Applicant"],["vacancy","Vacancy"],["job","Resulting job",true]])
map.logical_link("job-application","applicant","person")
map.logical_link("job-application","vacancy","vacancy")
map.logical_link("job-application","job","employment")

map.logical_object("school-experience","School experience",["start / end",["person","Person"],["school","School"]])
map.logical_link("school-experience","person","person")
map.logical_link("school-experience","school","location")

map.logical_object("itt-subject","ITT Subject",["funding / bursary info"])

map.logical_object("itt-course","ITT Course",[["provider","Provider"],["accreditor","Accreditor"],["subject","Subject"]])
map.logical_link("itt-course","provider","itt-provider")
map.logical_link("itt-course","accreditor","accredited-provider")
map.logical_link("itt-course","subject","itt-subject")

map.logical_object("itt-application","ITT Application",[["applicant","Applicatn"],["course","Course"],"status"])
map.logical_link("itt-application","applicant","person")
map.logical_link("itt-application","course","itt-course")

# Physical databases, synchronisations between them, and realisations of logical objects in them

# Synchronisation done within an existing component (like the updating of
# bigquery by the services) or by a dedicated data synchronising system should
# be indicated here; but any synchronisation that involves more complicated
# process should probably be indicated by an actor that talks to source and sink
# databases. Use your judgement to decide what would make for a clearer diagram.

map.physical_database("git crm")
map.realisation("person","git crm")

map.physical_database("publish db")
map.realisation("itt-provider","publish db")
map.realisation("itt-course","publish db")
map.realisation("itt-subject","publish db")
map.realisation("location","publish db")

map.physical_database("experience db")
map.physical_synch("gias db","experience db","nightly dump")
map.realisation("person","experience db")
map.realisation("location","experience db")
map.realisation("school-experience","experience db")

map.physical_database("apply db")
map.realisation("person","apply db")
map.realisation("itt-provider","apply db")
map.realisation("itt-course","apply db")
map.realisation("itt-subject","apply db")
map.realisation("itt-application","apply db")

map.physical_database("register db")
map.physical_synch("gias db","register db","manual dump")
map.realisation("person","register db","Trainee",["trainee_id","hesa_id","provider_id","trn?","dttp_id?","email~"])
map.realisation("person","register db","User",["dfe_sign_in_uid","dttp_id?"])
map.realisation("itt-provider","register db")
map.realisation("itt-course","register db")
map.realisation("itt-subject","register db")
map.realisation("itt-application","register db")
map.realisation("location","register db")

map.physical_database("dttp")
map.physical_synch("dttp","dqt","TRN allocation")
map.physical_synch("dttp","dqt","QTS award")
map.realisation("itt-provider","dttp")
map.realisation("person","dttp")

map.physical_database("dqt")
map.realisation("person","dqt")

map.physical_database("tps db")
map.realisation("person","tps db")

map.physical_database("gias db")
map.realisation("location","gias db")

map.physical_database("bigquery")
map.physical_synch("publish db","bigquery","stream")
map.physical_synch("apply db","bigquery","stream")
map.physical_synch("register db","bigquery","stream")

# Actors, and what physical DBs and other actors they use

map.actor("git")
map.actor_uses("git","git crm")

map.actor("find")
map.actor_uses("find","publish apis")

map.actor("apply")
map.actor_uses("apply","apply db")
map.actor_uses("apply","publish")

map.actor("manage")
map.actor_uses("manage","apply db")

map.actor("publish")
map.actor_uses("publish","publish apis")

map.actor("publish apis")
map.actor_uses("publish apis","publish db")

map.actor("tps")
map.actor_uses("tps","tps db")

map.actor("funding")
map.actor_uses("funding","dttp")

map.actor("nao","National Audit Office")
map.actor_uses("nao","dttp")

map.actor("mra","Market Regulation Authority")
map.actor_uses("mra","dttp")

map.actor("corpa","Corporate Assurance")
map.actor_uses("corpa","dttp")

map.actor("get experience","Get Experience")
map.actor_uses("get experience","experience db")

map.actor("tad","Teacher Analysis Division")
map.actor_uses("tad","apply db")
map.actor_uses("tad","dttp")
map.actor_uses("tad","dqt")

map.actor("gias","Get Information About Schools")
map.actor_uses("gias","gias db")

map.actor("register")
map.actor_uses("register","register db")

map.actor("hesa","HESA")
map.actor_uses("hesa","dttp")
map.actor_uses("hesa","dqt")

map.actor("claim")
map.actor_uses("claim","dqt")

map.actor("dashboards","Teacher Services Dashboards")
map.actor_uses("dashboards","bigquery")

## Final generation

map.generate_all_views()
