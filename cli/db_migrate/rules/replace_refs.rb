
module ProjectHanlon::DbMigration
  class MigrationRule
    class ReplaceRefs < ProjectHanlon::DbMigration::MigrationRule

attr_accessor :desc
      def initialize
        super

        @desc = "Replace ProjectRazor references with ProjectHanlon"

      end

      def exec(rec)
        doc = YAML.load rec.to_yaml
        doc.to_s.gsub! 'ProjectRazor', 'ProjectHanlon'
      end

    end
  end
end