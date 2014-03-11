module ProjectOccam
  module Error
    class Slice

      class Generic < ProjectOccam::Error::Generic

        def initialize(message)
          super(message)
          @http_err = :forbidden
          @std_err = 1
        end

      end

    end
  end
end
