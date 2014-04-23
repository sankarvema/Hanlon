require 'spec_helper'
require 'project_hanlon/slice/policy'
require 'project_hanlon/model/debian'

describe ProjectHanlon::Slice::Policy do
  subject('slice') { ProjectHanlon::Slice::Policy.new([]) }

  describe "hanlon policy add" do
    let('model') do
      model = ProjectHanlon::ModelTemplate::Debian.new({})

      # @todo danielp 2013-03-18: for now, this is required to make us connect
      # to the database, because the code still depends on every consumer of
      # database services being aware of, and responsible for, the full
      # life-cycle of those connections.  This needs to change.
      ProjectHanlon::Data.instance.check_init
      ProjectHanlon::Data.instance.persist_object(model)

      model
    end
    let('model_uuid') do model.uuid end

    subject('slice') do
      ProjectHanlon::Slice::Policy.new(%W[
        --template linux_deploy --label test_policy
        --model-uuid #{model_uuid} --tags domaincheck
        --enabled true
      ])
    end

    it "should be possible to add a policy" do
      stdout = console_output_of { slice.add_policy }[:stdout].strip_ansi_color
      stdout.should =~ /Label =>  test_policy/
      stdout.should =~ /Tags =>  \[domaincheck\]/
    end
  end

  # This checks for a bug found after pull request #437 was merged, where a
  # class that was not a classic object was added under the namespace.
  # Because we meta-program everything, this caused an error class to be
  # assumed to be a real broker plugin.  This ensures that doesn't sneak
  # in again.
  it "should be able to fetch all child template objects" do
    templates = slice.get_child_templates(ProjectHanlon::PolicyTemplate)
    templates.should_not be_empty
    templates.each {|t| t.should be_a ProjectHanlon::PolicyTemplate::Base }
  end
end
