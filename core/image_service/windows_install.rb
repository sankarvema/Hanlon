module ProjectHanlon
  module ImageService
    # Image construct for generic Operating System install ISOs
    class WindowsInstall < ProjectHanlon::ImageService::Base

      attr_accessor :os_name
      attr_accessor :wim_index
      attr_accessor :base_image_uuid

      def initialize(hash)
        super(hash)
        @description = "Windows Install"
        @path_prefix = "windows"
        @hidden = false
        from_hash(hash) unless hash == nil
      end

      def add(src_image_path, lcl_image_path)
        begin
          # for Windows ISOs, the 'fuseiso' command will not work so we have to restrict the
          # supported methods to only support the 'mount' command
          resp = super(src_image_path, lcl_image_path, { :verify_copy => false, :supported_methods => ['7z', 'mount'] })
          if resp[0]
            @os_name = "Windows (Base Image)"
            @wim_index = 0
            @base_image_uuid = @uuid
            @hidden = true
          end
          # check the resulting image; if the verification step fails, then cleanup and exit
          # (removes the image we just added and the underlying directory)
          result = verify(lcl_image_path)
          return cleanup_on_failure(true, true, result[1]) unless result[0]
          resp
        rescue => e
          logger.error e.message
          return [false, e.message]
        end
      end

      def image_path
        # if the base_image_uuid is set; return the path to that directory
        # (if not, then we're creating a base directory so just return
        # the path based on this image's uuid)
        return @_lcl_image_path + "/" + @base_image_uuid if @base_image_uuid
        @_lcl_image_path + "/" + @uuid
      end

      # Used to remove an image to the service
      # Within each child class the methods are overridden for that child template
      def remove(lcl_image_path)
        # skip removing the underlying image path unless we're removing a "base" image
        return true unless @uuid == @base_image_uuid
        set_lcl_image_path(lcl_image_path) unless @_lcl_image_path != nil
        super(lcl_image_path)
      end

      def verify(lcl_image_path)
        # set the 'lcl_image_path' if it is not already set
        set_lcl_image_path(lcl_image_path) unless @_lcl_image_path != nil
        # then test for validity; note that for Windows images, the only
        # really important thing is that we can find an 'install.wim' file
        # once the image is unpacked
        return [false, "'#{filename}' is not an Windows ISO"] if Dir["#{image_path}/**/install.wim"].empty?
        [true, '']
      end

      def print_item_header
        super.push "OS Name", "WIM Index", "Base Image"
      end

      def print_item
        super.push @os_name, @wim_index.to_s, @base_image_uuid
      end

    end
  end
end
