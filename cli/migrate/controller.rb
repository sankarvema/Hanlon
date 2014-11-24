require 'migrate/db/db_controller'

module ProjectHanlon::Migrate
  class Controller

    attr_accessor :db_objects

    def initialize
      @db_objects = %w"node model policy tag policy_rule bound_policy images active broker policy_table"
      #@db_objects = %w"tag"
    end

    def perform(action)
      puts
      config = ProjectHanlon::Config::Common.instance

      if(!dbs_active)
        return false
      end

      source_connection = ProjectHanlon::Migrate::DbController.new \
        config.source_persist_mode, config.source_persist_host, config.source_persist_port, config.source_persist_dbname, \
        config.source_persist_username, config.source_persist_password, config.source_persist_timeout

      dest_connection = ProjectHanlon::Migrate::DbController.new \
        config.destination_persist_mode, config.destination_persist_host, config.destination_persist_port, \
        config.destination_persist_dbname, \
        config.destination_persist_username, config.destination_persist_password, config.destination_persist_timeout

      rules = ObjectSpace.each_object(Class).select { |klass| klass < ProjectHanlon::Migrate::MigrationRule }
      puts "#{rules.count} migration rules found"

      rule_hash = Hash[rules.map { |a| [a.new().rule_name, a] }]

      collection_counts = Hash.new    #store object wise migration counts here

      # Process for each object
      @db_objects.each { |name|
        source_collection = source_connection.object_hash_get_all(name)
        source_count = source_collection.count

        puts "Processing data collection #{name} having (#{source_count} documents)".yellow

        doc_counter = 1
        #puts source_collection.find().count
        source_collection.find().each { |row|
          #puts source_collection.count
          #puts row
          doc = YAML.load row.to_yaml

          rec_id = rec_id(doc)
          row_summary = "#{doc_counter.to_s.ljust(5)} | #{rec_id.ljust(30)}"

          doc_new = doc
          rule_counter = 1
          rule_hash.keys.sort.each do |rule_name|
            rule_obj = rule_hash[rule_name].new()
            print "\r#{row_summary} | #{rule_counter} | #{rule_obj.desc.ljust(50)} | Running..."
            doc_new = rule_obj.exec(doc_new)
            print "\r#{row_summary} | #{rule_counter} | #{rule_obj.desc.ljust(50)} | Processed"
            rule_counter = rule_counter + 1
          end # end of rule loop

          if action=="run"
            dest_connection.object_hash_update doc_new, name
            message="Save document to destination"
            print "\r#{row_summary} | #{rule_counter-1} | #{message.ljust(50)} | Migrated"
          end
          puts
          doc_counter=doc_counter + 1
        } # end of doc loop


      } #end of collection loop


    end

    def rec_id(rec)
      rec.fetch('@uuid')
    end

    def dbs_active
      config = ProjectHanlon::Config::Common.instance
      
      source_connection = Mongo::Connection.new(config.source_persist_host, config.source_persist_port)
      dist_connection = Mongo::Connection.new(config.destination_persist_host, config.destination_persist_port)
      source_db= source_connection.db(config.source_persist_dbname)
      dest_db= dist_connection.db(config.destination_persist_dbname)


      source_active = source_connection.active?
      dest_active = dist_connection.active?

      puts "Check parameters...".yellow
      puts "\tSource database connection:: #{ source_active ? 'OK':'Failed'}"
      puts "\tDestination database connection:: #{ dest_active ? 'OK':'Failed'}"

      return dest_active && source_active
    end
  end
end