# Root ProjectHanlon namespace
module ProjectHanlon
  module ModelTemplate
    # Root Model object
    # @abstract
    class VMwareESXi5vSAN < ProjectHanlon::ModelTemplate::VMwareESXi

      def initialize(hash)
        super(hash)
        # Static config
        @hidden = false
        @name = "vmware_esxi_5_vsan"
        @description = "VMware ESXi 5 vSAN Deployment"
        @osversion = "5_vsan"

        @req_metadata_hash["@vsan_uuid"] = { :default     => UUID.generate,
                                                          :example     => "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
                                                          :validation  => '^[a-z\d]{8}-[a-z\d]{4}-[a-z\d]{4}-[a-z\d]{4}-[a-z\d]{12}$',
                                                          :required    => true,
                                                          :description => "VMware vSAN UUID.  Use the default or type in"
        }

        from_hash(hash) unless hash == nil
      end
    end
  end
end
