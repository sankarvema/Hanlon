require 'mongo'

module ProjectHanlon::Migrate
  class DbController
    include(ProjectHanlon::Logging)

    attr_accessor :db_mode
    attr_accessor :db_host
    attr_accessor :db_port
    attr_accessor :db_username
    attr_accessor :db_password
    attr_accessor :db_timeout
    attr_accessor :db_dbname

    attr_accessor :database

    def initialize(mode, host, port, name, username, password, timeout)

      @db_mode=mode
      @db_host=host
      @db_port=port
      @db_name=name
      @db_username=username
      @db_password=password
      @db_timeout=timeout

      if (db_mode == :mongo)
        logger.debug "Using Mongo plugin"
        require "migrate/db/mongo_plugin" unless ProjectHanlon::Migrate.const_defined?(:MongoPlugin)
        @database = ProjectHanlon::Migrate::MongoPlugin.new
      elsif (db_mode == :postgres)
        logger.debug "Using Postgres plugin"
        require "migrate/db/postgres_plugin" unless ProjectHanlon::Migrate.const_defined?(:PostgresPlugin)
        @database = ProjectHanlon::Migrate::PostgresPlugin.new
      else
        logger.error "Invalid Database plugin(#{db_mode})"
        return;
      end
      check_connection

    end

    # This is where all connection teardown is started. Calls the '@database.teardown'
    def teardown
      logger.debug "Connection teardown"
      @database.teardown
    end

    # Returns true|false whether DB/Connection is open
    # Use this when you want to check but not reconnect
    # @return [true, false]
    def is_connected?
      logger.debug "Checking if DB is selected(#{@database.is_db_selected?})"
      @database.is_db_selected?
    end

    # Checks and reopens closed DB/Connection
    # Use this to check connection after trying to make sure it is open
    # @return [true, false]
    def check_connection
      logger.debug "Checking connection (#{is_connected?})"
      is_connected? || connect_database
      # return connection status
      is_connected?
    end

    # Connect to database using ProjectHanlon::Persist::Database::Plugin loaded
    def connect_database
      #logger.debug "Connecting to database(#{@db_username}#{@db_host}:#{@db_port}) with timeout(#{@db_timeout})"
      @database.connect(@db_host, @db_port, @db_name, @db_username, @db_password, @db_timeout)
    end

    def is_db_empty
      @database.is_db_empty
    end

    # Get all object documents from database collection: 'collection'
    # @param collection [Symbol] - name of the collection
    # @return [Array] - Array containing the
    def object_hash_get_all(collection)
      logger.debug "Retrieving object documents from collection(#{collection})"
      @database.object_doc_get_all(collection)
    end

    def object_hash_get_by_uuid(object_doc, collection)
      logger.debug "Retrieving object document from collection(#{collection}) by uuid(#{object_doc['@uuid']})"
      @database.object_doc_get_by_uuid(object_doc, collection)
    end

    # Add/update object document to the collection: 'collection'
    # @param object_doc [Hash]
    # @param collection [Symbol]
    # @return [Hash]
    def object_hash_update(object_doc, collection)
      logger.debug "Updating object document from collection(#{collection}) by uuid(#{object_doc['@uuid']})"
      #puts "Updating object document from collection(#{collection}) by uuid(#{object_doc['@uuid']})"
      @database.object_doc_update(object_doc, collection)
    end

  end
end