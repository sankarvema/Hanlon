
module ProjectHanlon::DbMigration
  class MigrationRule
    class ReplaceRefs < ProjectHanlon::DbMigration::MigrationRule

attr_accessor :desc
      def initialize
        super

        @desc = "Replace ProjectRazor references with ProjectHanlon"

      end

      def exec(rec)
        doc = rec
        doc.each {|k,v|
          doc[k] = v.to_s.gsub! 'ProjectRazor', 'ProjectHanlon' if v.to_s.include? "ProjectRazor"
        }
        return doc
      end
    end
  end
end