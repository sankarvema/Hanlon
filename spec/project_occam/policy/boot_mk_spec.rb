require 'spec_helper'
require 'project_occam/policy/boot_mk'
require 'project_occam'

describe ProjectOccam::PolicyTemplate::BootMK do
  describe ".get_boot_script" do
    # A helper to do all the setup required, and then generate our boot
    # script, for testing.
    def boot_script(settings)
      settings.each_pair do |key, value|
        ProjectOccam.config[key] = value
      end

      ProjectOccam::PolicyTemplate::BootMK.new({}).
        get_boot_script(ProjectOccam::ImageService::MicroKernel.new({}))
    end

    it "should append the contents of rz_mk_boot_kernel_args to the iPXE kernel-line, if configured" do
      boot_script('rz_mk_boot_kernel_args' => 'occam.ip=1.2.3.4').should include('occam.ip=1.2.3.4')
    end

    it "should append the contents of rz_mk_boot_debug_level if it is configured and matches 'quiet'" do
      boot_script('rz_mk_boot_debug_level' => 'quiet').should include('quiet')
    end

    it "should append the contents of rz_mk_boot_debug_level if it is configured and matches 'debug'" do
      boot_script('rz_mk_boot_debug_level' => 'debug').should include('debug')
    end

    it "should not append the contents of rz_mk_boot_debug_level if it does not match 'quiet' or 'debug'" do
      boot_script('rz_mk_boot_debug_level' => 'fubar').should_not include('fubar')
    end

    it "should append the contents of rz_mk_boot_debug_level + rz_boot_kernel_args if both are configured" do
      boot_script('rz_mk_boot_debug_level' => 'debug',
        'rz_mk_boot_kernel_args' => 'occam.ip=1.2.3.4'
      ).should include('debug occam.ip=1.2.3.4')
    end
  end
end

