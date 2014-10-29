require 'mongo'

module ProjectHanlon::DbMigration
  class Controller

    attr_accessor :db_objects



    def initialize
      @db_objects = %w"node model policy tag policy_rule bound_policy bmc images systems active broker policy_table"
    end

    def test
      puts "Exec migrate test..."

      connection = Mongo::Connection.new("localhost", 27017)#.db("project_razor")

      #puts "Databases"
      #connection.database_names.each { |name| puts "   #{name}" }
      #puts "DB Info"
      #connection.database_info.each { |info| puts "    #{info.inspect}"}

      db= connection.db("project_razor")
      #db = Mongo::Connection.new("localhost", 27017).db("project_hanlon")
      #db.authenticate('','')
      rules = ObjectSpace.each_object(Class).select { |klass| klass < ProjectHanlon::DbMigration::MigrationRule }
      puts "#{rules.count} migration rules found"
      rule_hash = Hash[rules.map { |a| [a.new().rule_name, a] }]

      #puts "migration rules:: " + rule_hash.inspect

      #puts "DB Collections..."
      #db.collection_names.each { |name| puts name }

      @db_objects.each { |name|
      #db.collection_names.each { |name|
        coll = db.collection(name)
        puts "Processing data collection #{name} having (#{coll.count} documents)".yellow


        #puts "   Collection documents"
        doc_counter = 1
        coll.find().each { |row|
          #puts "      {#{row.to_yaml}}"
          doc = YAML.load row.to_yaml
          doc_new = doc.to_s.gsub! 'ProjectRazor', 'ProjectHanlon'
          #puts "=" * 20
          #puts "Doc uuid:: #{rec_id(doc)}"
          #puts "Original doc:: #{doc}"
          #puts "-" * 20

          row_summary = "#{doc_counter.to_s.ljust(5)} | #{rec_id(doc).ljust(30)}"

          doc_new = doc
          rule_counter = 1
          rule_hash.keys.sort.each do |rule_name|
            rule_obj = rule_hash[rule_name].new()
            print "\r#{row_summary} | #{rule_counter} | #{rule_obj.desc.ljust(30)} | Running..."
            doc_new = rule_obj.exec doc_new
            print "\r#{row_summary} | #{rule_counter} | #{rule_obj.desc.ljust(30)} | Complete"
            rule_counter = rule_counter + 1
          end
          puts
          #puts "Migrated doc: #{doc_new}"
          #puts "=" * 20

          #doc = JSON(row.inspect.to_json)
          #ProjectHanlon::Utility.print_yaml row.to_yaml
          doc_counter=doc_counter + 1
        }


      }

    end

    def rec_id(rec)
      rec.fetch('@uuid')
    end
  end
end