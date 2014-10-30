require 'mongo'

module ProjectHanlon::DbMigration
  class Controller

    attr_accessor :db_objects

    def initialize
      @db_objects = %w"node model policy tag policy_rule bound_policy bmc images systems active broker policy_table"
    end

    def perform(action)
      puts
      config = ProjectHanlon::Config::Common.instance

      source_connection = Mongo::Connection.new(config.source_persist_host, config.source_persist_port)
      dist_connection = Mongo::Connection.new(config.destination_persist_host, config.destination_persist_port)


      source_db= source_connection.db(config.source_persist_dbname)
      dest_db= dist_connection.db(config.destination_persist_dbname)

      rules = ObjectSpace.each_object(Class).select { |klass| klass < ProjectHanlon::DbMigration::MigrationRule }
      puts "#{rules.count} migration rules found"

      rule_hash = Hash[rules.map { |a| [a.new().rule_name, a] }]

      collection_counts = Hash.new

      # Process for each object
      @db_objects.each { |name|
      #db.collection_names.each { |name|
        source_collection = source_db.collection(name)
        source_count = source_collection.count

        dest_collection = dest_db.collection(name)
        dest_count = dest_collection.count

        puts "Processing data collection #{name} having (#{source_count} documents)".yellow

        doc_counter = 1
        source_collection.find().each { |row|
          doc = YAML.load row.to_yaml

          rec_id = rec_id(doc)
          row_summary = "#{doc_counter.to_s.ljust(5)} | #{rec_id.ljust(30)}"

          doc_new = doc
          rule_counter = 1
          rule_hash.keys.sort.each do |rule_name|
            rule_obj = rule_hash[rule_name].new()
            print "\r#{row_summary} | #{rule_counter} | #{rule_obj.desc.ljust(50)} | Running..."
            doc_new = rule_obj.exec doc_new
            print "\r#{row_summary} | #{rule_counter} | #{rule_obj.desc.ljust(50)} | Processed"
            rule_counter = rule_counter + 1
          end # end of rule loop

          if action=="run" then
            id=dest_collection.insert({rec_id=>doc_new})
            message="Save document to destination"
            print "\r#{row_summary} | #{rule_counter-1} | #{message.ljust(50)} | Migrated"
          end
          puts
          #puts "Migrated doc: #{doc_new}"
          #puts "=" * 20

          #doc = JSON(row.inspect.to_json)
          #ProjectHanlon::Utility.print_yaml row.to_yaml
          doc_counter=doc_counter + 1
        } # end of doc loop

        new_dest_collection=dest_db.collection(name)
        new_dest_count = new_dest_collection.count

        collection_counts[name] = Array[source_count, dest_count, new_dest_count]
      } #end of collection loop

      #verify db after migrate

      puts
      puts "Verify migration process...".blue
      puts "#{'Collection'.ljust(30)} | #{'Source'.rjust(10)} | #{'Dest'.rjust(10)} | #{'Migrated'.rjust(10)}".bold
      @db_objects.each { |name|
        puts "#{name.ljust(30)} | #{collection_counts[name][0].to_s.rjust(10)} | #{collection_counts[name][1].to_s.rjust(10)} | #{collection_counts[name][2].to_s.rjust(10)}\n"
      }


    end

    def rec_id(rec)
      rec.fetch('@uuid')
    end
  end
end