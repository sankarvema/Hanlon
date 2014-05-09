#
#require "project_hanlon"
#require "rspec"
#
#describe ProjectHanlon::ImageService do
#
#  before(:all) do
#    @data = ProjectHanlon::Data.instance
#    @data.check_init
#    @config = @data.config
#  end
#
#
#  describe ".Microkernel" do
#    it "should do something" do
#      new_mk = ProjectHanlon::ImageService::MicroKernel.new({})
#      resp = new_mk.add("#{$hanlon_root}/rz_mk_dev-image.0.2.1.0.iso", @config.image_path)
#      p resp
#      p new_mk
#
#      v = new_mk.verify(@config.image_path)
#      puts "Verify: #{v}"
#    end
#
#  end
#end
