module ProjectHanlon
  module ImageService
    # Image construct for generic Operating System install ISOs
    class WindowsInstall < ProjectHanlon::ImageService::Base

      attr_accessor :os_name
      attr_accessor :os_version

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
          resp = super(src_image_path, lcl_image_path, { :verify_copy => false, :supported_methods => ['mount'] })
          if resp[0]
            # TODO: replace this with code that adds in images for each entry in the install.wim file
            # (with names for each that are also extracted from that same file)
            @os_name = "Windows (Generic)"
          end
          resp
        rescue => e
          logger.error e.message
          return [false, e.message]
        end
      end

      # TODO: override the remove so that it supports 'removal by reference'
      # only when the last reference to the underlying directory is removed
      # should the underlying directory be removed???

      def verify(lcl_image_path)
        # check to make sure that the hashes match (of the file list
        # extracted and the file list from the ISO)
        # is_valid, result = super(lcl_image_path)
        # unless is_valid
        #   return [false, result]
        # end

        # For Windows images, the only really important thing is that we
        # can find the 'install.wim' file once the image is unpacked
        [true, '']
      end

      def print_item_header
        # super.push "OS Name", "OS Version"
        super.push "OS Name", "OS Version"
      end

      def print_item
        # super.push @os_name.to_s, @os_version.to_s
        super.push @os_name.to_s, @os_version.to_s
      end

    end
  end
end
