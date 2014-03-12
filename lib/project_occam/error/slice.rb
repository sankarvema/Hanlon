require_rel "slice/"

module ProjectOccam
  module Error
    class Slice

      [
          [ 'InputError'                , 111 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidPlugin'             , 112 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidTemplate'           , 113 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'MissingArgument'           , 114 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidCommand'            , 115 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidUUID'               , 116 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'MissingMK'                 , 117 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidPathItem'           , 118 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidImageFilePath'      , 119 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'CommandFailed'             , 120 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidImageType'          , 121 , {'@http_err' => :bad_request}           , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'SliceCommandParsingFailed' , 122 , {'@http_err' => :not_found}             , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'NotFound'                  , 123 , {'@http_err' => :not_found}             , 'Not found' , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'CouldNotRegisterNode'      , 124 , {'@http_err' => :not_found}             , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InternalError'             , 131 , {'@http_err' => :internal_server_error} , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'NotImplemented'            , 141 , {'@http_err' => :forbidden}             , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'CouldNotCreate'            , 125 , {'@http_err'=> :forbidden}              , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'CouldNotUpdate'            , 126 , {'@http_err'=> :forbidden}              , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'CouldNotRemove'            , 127 , {'@http_err'=> :forbidden}              , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'MethodNotAllowed'          , 128 , {'@http_err'=> :method_not_allowed}     , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidModelTemplate'      , 150 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'UserCancelled'             , 151 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'MissingModelMetadata'      , 152 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidModelMetadata'      , 153 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidPolicyTemplate'     , 154 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidModel'              , 155 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'MissingTags'               , 156 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'NoCallbackFound'           , 157 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'MissingActiveModelUUID'    , 158 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'MissingCallbackNamespace'  , 159 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'ActiveModelInvalid'        , 160 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidMaximumCount'       , 161 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'MissingBrokerMetadata'     , 162 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
          [ 'InvalidBrokerMetadata'     , 163 , {'@http_err'=> :bad_request}            , ''          , 'ProjectOccam::Error::Slice::Generic' ],
      ].each do |err|
        ProjectOccam::Error.create_class *err
      end

    end
  end
end
