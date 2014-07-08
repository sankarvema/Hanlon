require "yaml"
require "digest/sha2"
require "image_service/base"

module ProjectHanlon
  module ImageService
    # Image construct for Microkernel files
    class MicroKernel < ProjectHanlon::ImageService::Base
      attr_accessor :mk_version
      attr_accessor :kernel
      attr_accessor :initrd
      attr_accessor :kernel_hash
      attr_accessor :initrd_hash
      attr_accessor :hash_description
      attr_accessor :iso_build_time
      attr_accessor :iso_version

      def initialize(hash)
        super(hash)
        @description = "MicroKernel Image"
        @path_prefix = "mk"
        @hidden = false
        from_hash(hash) unless hash == nil
      end

      def add(src_image_path, lcl_image_path, extra)
        # Add the iso to the image svc storage

        begin
          resp = super(src_image_path, lcl_image_path, extra)
          if resp[0]
            success, result_string = verify(lcl_image_path)
            unless success
              logger.error result_string
              return [false, result_string]
            end
            return resp
          else
            resp
          end
          rescue => e
            #logger.error e.message
            logger.log_exception e
            raise ProjectHanlon::Error::Slice::InternalError, e.message
        end
      end

      def verify(lcl_image_path)
        # check to make sure that the hashes match (of the file list
        # extracted and the file list from the ISO)
        unless super(lcl_image_path)
          logger.error "ISO file structure is invalid"
          return [false, "ISO file structure is invalid"]
        end
        # if the ISO includes an "iso-metadata.yaml" file, check the
        # contents and make sure the required fields are included
        if File.exist?("#{image_path}/iso-metadata.yaml")
          # first, read the parameters
          File.open("#{image_path}/iso-metadata.yaml","r") do
          |f|
            @_meta = YAML.load(f)
          end
          # set the hash variables from those parameters
          set_hash_vars
          # check the kernel_path parameter value
          unless File.exists?(kernel_path)
            logger.error "missing kernel: #{kernel_path}"
            return [false, "missing kernel: #{kernel_path}"]
          end
          # check the initrd_path parameter value
          unless File.exists?(initrd_path)
            logger.error "missing initrd: #{initrd_path}"
            return [false, "missing initrd: #{initrd_path}"]
          end
          # check the build_time parameter value
          if @iso_build_time == nil
            logger.error "ISO build time is nil"
            return [false, "ISO build time is nil"]
          end
          # check the iso_version parameter value
          if @iso_version == nil
            logger.error "ISO version is nil"
            return [false, "ISO version is nil"]
          end
          # check the hash_description parameter value
          if @hash_description == nil
            logger.error "Hash description is nil"
            return [false, "Hash description is nil"]
          end
          # check the kernel_hash parameter value
          if @kernel_hash == nil
            logger.error "Kernel hash is nil"
            return [false, "Kernel hash is nil"]
          end
          # check the initrd_hash parameter value
          if @initrd_hash == nil
            logger.error "Initrd hash is nil"
            return [false, "Initrd hash is nil"]
          end
          # and use the hash values to check the kernel and initrd files
          digest = ::Object::full_const_get(@hash_description["type"]).new(@hash_description["bitlen"])
          khash = File.exist?(kernel_path) ? digest.hexdigest(File.read(kernel_path)) : ""
          ihash = File.exist?(initrd_path) ? digest.hexdigest(File.read(initrd_path)) : ""
          unless @kernel_hash == khash
            logger.error "Kernel #{@kernel} is invalid"
            return [false, "Kernel #{@kernel} is invalid"]
          end
          unless @initrd_hash == ihash
            logger.error "Initrd #{@initrd} is invalid"
            return [false, "Initrd #{@initrd} is invalid"]
          end
          # if all of those checks passed, then return success
          [true, '']
        else
          logger.error "Missing metadata file '#{image_path}/iso-metadata.yaml'"
          [false, "Missing metadata file '#{image_path}/iso-metadata.yaml'"]
        end
      end

      def set_hash_vars
        if @iso_build_time ==nil ||
            @iso_version == nil ||
            @kernel == nil ||
            @initrd == nil

          @iso_build_time = @_meta['iso_build_time'].to_i
          @iso_version = @_meta['iso_version']
          @kernel = @_meta['kernel']
          @initrd = @_meta['initrd']
        end

        if @kernel_hash == nil ||
            @initrd_hash == nil ||
            @hash_description == nil

          @kernel_hash = @_meta['kernel_hash']
          @initrd_hash = @_meta['initrd_hash']
          @hash_description = @_meta['hash_description']
        end
      end

      # Used to calculate a "weight" for a given ISO version.  These weights
      # are used to determine which ISO to use when multiple Hanlon-Microkernel
      # ISOS are available.  The complexity in this function results from it's
      # support for the various version numbering schemes that have been used
      # in the Hanlon-Microkernel project over time.  The following four version
      # numbering schemes are all supported:
      #
      #    v0.9.3.0
      #    v0.9.3.0+48-g104a9bc
      #    0.10.0
      #    0.10.0+4-g104a9bc
      #
      # Note that the syntax that is supported is an optional 'v' character
      # followed by a 3 or 4 part version number.  Either of these two formats
      # can be used for the "version tag" that is applied to any given
      # Hanlon-Microkernel release.  The remainder (if it exists) shows the commit
      # number and commit string for the latest commit (if that commit differs
      # from the tagged version).  These strings are converted to a floating point
      # number for comparison purposes, with later releases (in the semantic
      # versioning sense of the word "later") converting to larger floating point
      # numbers
      def version_weight
        # parse the version numbers from the @iso_version value
        version_str, commit_no = /^v?(.*)$/.match(@iso_version)[1].split("-")[0].split("+")
        # Limit any part of the version number to a number that is 999 or less
        version_str.split(".").map! {|v| v.to_i > 999 ? 999 : v}.join(".")
        # separate out the semantic version part (which looks like 0.10.0) from the
        # "sub_patch number" (to handle formats like v0.9.3.0, which were used in
        # older versions of the Hanlon-Microkernel project)
        version_parts = version_str.split(".").map {|x| "%03d" % x}
        sub_patch = (version_parts.length == 4 ? version_parts[3] : "000")
        # and join the parts as a single floating point number for comparison
        (version_parts[0,3].join + ".#{sub_patch}").to_f + "0.000#{commit_no}".to_f
      end

      def print_item_header
        super.push "Version", "Built Time"
      end

      def print_item
        super.push @iso_version.to_s, (Time.at(@iso_build_time)).to_s
      end

      def kernel_path
        image_path + "/" + @kernel
      end

      def initrd_path
        image_path + "/" + @initrd
      end

    end
  end
end
