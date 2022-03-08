## Types

LogicalObjectPart = Struct.new(:id,:name,:optional?)
LogicalObject = Struct.new(:id,:name,:parts)
LogicalLink = Struct.new(:source_object,:source_part,:target_object)
PhysicalDatabase = Struct.new(:id,:name)
PhysicalSynchronization = Struct.new(:source_db,:target_db,:trigger)
Representation = Struct.new(:logical_object,:physical_database,:table,:keys)
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

class Representation
  # De-dupe realization arcs, when the object is realised in multiple tables in
  # the same physical DB just draw one arrow
  def initialize(logical_object, physical_database, table, keys)
    @@already_done = Hash.new()
    super(logical_object, physical_database, table, keys)
  end
  def render
    if not @@already_done[self.logical_object + "->" + self.physical_database]
      print "\"#{self.logical_object}\" -> \"#{self.physical_database}\" [arrowhead = curve; style = dotted"
      # Including the table names made the diagram too cluttered
      #    if self.table != nil
      #      print "; headlabel=\"#{self.table}\""
      #    end
      puts "]"
      @@already_done[self.logical_object + "->" + self.physical_database] = true
    end
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
    @representations = Array.new()
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

  def representation(logical_object,physical_database,table=nil,keys=[])
    @representations.push(Representation.new(logical_object,physical_database,table,keys))
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

  def generate_representation_view()
    puts "digraph \"DfE Representations\" {"
    render (@logical_objects)
    render (@physical_dbs)
    render (@representations)
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

  def generate_representation_html_view()
    puts "<html>"
    puts "<head>"
    puts "<style>"
    puts "table { border-collapse: collapse; }"
    puts "th { background: rgb(200,200,255); margin: 0px; padding: 8pt}"
    puts "td { border-bottom: 1px solid black; margin: 0px; padding: 8pt}"
    puts ".unknown { color: #999; font-style: italic }"
    puts "</style>"
    puts "</head>"
    puts "<body>"
    puts "<table>"
    puts "<tr><th>Logical Object</th><th>Physical Database</th><th>Table [ : Key]</th></tr>"
    @representations.sort { |a,b| a.logical_object <=> b.logical_object }.each do |representation|
      object_name = @nodes[representation.logical_object].name
      db_name = @nodes[representation.physical_database].name
      if representation.table != nil
        if representation.keys.length == 0
          puts "<tr><td>#{object_name}</td><td>#{db_name}</td><td>#{representation.table}</td></tr>"
        else
          kr = render_key_html(representation.keys.first)
          puts "<tr><td rowspan=\"#{representation.keys.length}\">#{object_name}</td><td rowspan=\"#{representation.keys.length}\">#{db_name}</td><td>#{representation.table} : #{kr}</td></tr>"
          representation.keys[1..].each do |key|
            kr = render_key_html(key)
            puts "<tr><td>#{representation.table} : #{kr}</td></tr>"
          end
        end
      else
        puts "<tr><td>#{object_name}</td><td>#{db_name}</td><td class=\"unknown\">unknown</td></tr>"
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
    
    $stdout = File.new("representations.dot","w")
    generate_representation_view()
    $stdout.close()
    
    $stdout = File.new("representations.html","w")
    generate_representation_html_view()
    $stdout.close()
    
    $stdout = File.new("actors_dbs.dot","w")
    generate_actors_view()
    $stdout.close()

    $stdout = old_stdout
  end
end
