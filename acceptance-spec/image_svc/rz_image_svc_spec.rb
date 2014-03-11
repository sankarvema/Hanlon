#
#require "project_occam"
#require "rspec"
#
#describe ProjectOccam::ImageService do
#
#  before(:all) do
#    @data = ProjectOccam::Data.instance
#    @data.check_init
#    @config = @data.config
#  end
#
#
#  describe ".Microkernel" do
#    it "should do something" do
#      new_mk = ProjectOccam::ImageService::MicroKernel.new({})
#      resp = new_mk.add("#{$occam_root}/rz_mk_dev-image.0.2.1.0.iso", @config.image_svc_path)
#      p resp
#      p new_mk
#
#      v = new_mk.verify(@config.image_svc_path)
#      puts "Verify: #{v}"
#    end
#
#  end
#end
