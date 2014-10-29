
Dir[File.dirname(__FILE__) + "/rules/**/*.rb"].each do |file|
  require file
end

module ProjectHanlon::DbMigration
  class MigrationRule

    # Return the name of this slice - essentially, the final classname without
    # the leading hierarchy, in Ruby "filename" format rather than "classname"
    # format.  Not cached, because this is seldom used, and is never on the
    # hot path.
    def rule_name
      self.class.name.
          split('::').
          last.
          scan(/[[:upper:]][[:lower:]]*/).
          join('_').
          downcase
    end

  end
end