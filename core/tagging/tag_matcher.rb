
# TODO add 'ALL' matcher compare

module ProjectHanlon
  module Tagging
    class TagMatcher < ProjectHanlon::Object
      include(ProjectHanlon::Logging)

      attr_accessor :key          # the attribute key we want to match
      attr_accessor :compare      # either "equal" or "like"
      attr_accessor :value        # value as String - if @compare == "like" then will be converted to Regex
      attr_accessor :inverse      # true = flip operation result

      # Equal to
      # Not Equal to
      # Like
      # Not Like

      # Key Equal to String | Not
      # Key Like String(Regex) | not

      def initialize(hash, tag_matcher_uuid)
        super()

        @noun = "tag/#{tag_matcher_uuid}/matcher"
        from_hash(hash) unless hash == nil
        if @compare != "equal" && @compare != "like"
          @compare = nil
        end

        if @inverse != "true" && @inverse != "false"
          @inverse = nil
        end
      end

      # @param property_value [String]
      def check_for_match(property_value_in)
        ret = true
        ret = false if @inverse == "true"
        property_value = property_value_in

        case compare
          when "equal"
            # ensure that we won't compare a string 'true' value with a boolean true value
            property_value = property_value.to_s if property_value.class == TrueClass
            logger.debug "Checking if key:#{@key}=#{property_value} is equal to matcher value:#{@value}"
            if property_value == @value
              logger.debug "Match found"
              return ret
            else
              logger.debug "Match not found"
              return !ret
            end
          when "like"
            logger.debug "Checking if key:#{@key}=#{property_value} is like matcher pattern:#{@value}"
            reg_ex = Regexp.new(@value)
            if (reg_ex =~ property_value.to_s) != nil
              logger.debug "Match found #{ret}"
              return ret
            else
              logger.debug "Match not found #{!ret}"
              return !ret
            end
          else
            logger.error "Bad compare symbol"
            return :error
        end
      end


      def print_header
        return "Key", "Compare", "Value",  "Inverse", "UUID"
      end

      def print_items
        return @key, @compare, @value, @inverse, @uuid
      end

      def line_color
        :white_on_black
      end

      def header_color
        :red_on_black
      end


    end
  end
end

