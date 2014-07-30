#

require 'rufus-scheduler'
require 'uri'
require 'api'

require 'helper/swagger'

module Hanlon
  module WebService
    class App
      include ProjectHanlon::Logging

      CHUNK_SIZE = 2**20

      def initialize

        #config = ProjectHanlon::Config::Server.instance
        config = $config
        if config.nil?
          abort("Aborting hanlon server")
        end

        #ToDo::Sankar:Implement - this logic should be generic to allow static html pages and through http error pages
        #if SERVICE_CONFIG[:config][:swagger_ui] && SERVICE_CONFIG[:config][:swagger_ui][:allow_access]

        if ProjectHanlon::Helper::Swagger.allow_swagger_access
          @filenames = [ '', '.html', 'index.html', '/index.html' ]
          @rack_static = ::Rack::Static.new(
              lambda { [404, {}, ['http error 404 - file not found']] }, {
              :root => File.expand_path('../../public', __FILE__),
              :urls => %w[/]
          })
          @image_static = ::Rack::Static.new(
              lambda { [404, {}, []] }, {
              :root => File.expand_path('../../', __FILE__),
              :urls => %w[/]
          })
        end
        # starts up a set of tasks (using the rufus-scheduler gem) that will maintain
        # (and monitor) the system
        start_scheduled_tasks
      end

      def call(env)

        request_path = env['PATH_INFO']

        #if SERVICE_CONFIG[:config][:swagger_ui] && SERVICE_CONFIG[:config][:swagger_ui][:allow_access]

        if ProjectHanlon::Helper::Swagger.allow_swagger_access
          # in cases where the URL entered by the user ended with a slash,
          # the paths can have a duplicate first directory in the front of
          # the request path.  The following is a hack to deal with that
          # issue (should it arise).  First, parse out the first two
          # "fields" (using the '/' as a separator) using a regex
          match = /^(\/[^\/]+)(\/[^\/]+)(.*)$/.match(request_path)

          # if there was a match, and if the first two fields are identical,
          # then remove the first and keep just the second and third as the
          # new value for the 'request_path'
          if match && match[1] == match[2]
            request_path = match[2] + match[3]
          end

          # check to see if the requested resource can be loaded as a static file
          @filenames.each do |path|
            response = @rack_static.call(env.merge({'PATH_INFO' => request_path + path}))
            return response unless [ 404, 405 ].include?(response[0])
          end
        end

        matches_image = /^(\/v1)(\/image)(\/.*)$/.match(URI.unescape(request_path))

        #matches_image.each { |a| puts ">>>#{a} " }

        if matches_image
          file = File.join(ProjectHanlon.config.image_path, matches_image[3])

          if File.exists?(file) && File.file?(file)
            response = Rack::Response.new
            if /\.rpm$/.match(file)
              response["Content-Type"] = "application/x-rpm"
            else
              response["Content-Type"] = "application/octet-stream"
            end
            response["Connection"] = 'close'
            response["Accept-Ranges"] = 'bytes'
            open(file, 'rb') do |f|
              start_offset = nil
              end_offset = nil
              http_range = env['HTTP_RANGE']
              if http_range
                vals = http_range.split(/\s+|=|-|\//)
                start_offset = vals[1].to_i
                end_offset = vals[2].to_i
              else
                start_offset = 0
                end_offset = f.size - 1
              end
              f.seek(start_offset) if start_offset > 0
              nbytes_read = end_offset - f.pos + 1
              if nbytes_read > CHUNK_SIZE
                until f.pos >= end_offset || f.eof?
                  nbytes_read = [CHUNK_SIZE, end_offset - f.pos + 1].min
                  response.write f.read(nbytes_read)
                end
              else
                response.write f.read(nbytes_read)
              end
              if start_offset || end_offset < f.size
                # if here, is a partial response
                response['Content-Range'] = "bytes #{start_offset}-#{end_offset}/#{response['Content-Length']}"
              end
            end
            return response.finish
          end
        end

        # if not, then load it via the api
        @@base_uri = env['SCRIPT_NAME']

        Hanlon::WebService::API.call(env)
      end

      def self.base_uri
        @@base_uri
      end

      # define a class-method that can be used to shut down any periodic tasks
      # that might be running
      def self.stop_periodic_tasks
        # collect together the set of jobs we have running
        jobs = Rufus::Scheduler.singleton.jobs(:tag => 'periodic_hanlon_tasks')
        jobs.push *(Rufus::Scheduler.singleton.jobs(:tag => 'track_hanlon_tasks'))
        # and for each job, shut them down
        jobs.each { |job|
          puts "Shutting down job => #{job.id}"
          job.kill && job.unschedule
        }
      end

      private

      def start_scheduled_tasks
        node_timeout = ProjectHanlon.config.node_expire_timeout
        node_timeout ||= DEFAULT_NODE_EXPIRE_TIMEOUT
        min_cycle_time = ProjectHanlon.config.daemon_min_cycle_time
        min_cycle_time ||= DEFAULT_MIN_CYCLE_TIME
        begin
          # check to make sure there isn't already a set of 'periodic_hanlon_tasks'
          # running; if there is, then skip this step
          if Rufus::Scheduler.singleton.jobs(:tag => 'periodic_hanlon_tasks')
            # start a thread that will remove any inactive nodes from the nodes list
            # (inactive nodes haven't checked in for a while and aren't bound to a model
            # via an active_model instance)

            puts ">> Starting new thread to remove inactive nodes; cycle time => #{min_cycle_time}, timeout => #{node_timeout}"
            logger.debug ">> Starting new thread to remove inactive nodes; cycle time => #{min_cycle_time}, timeout => #{node_timeout}"

            Rufus::Scheduler.singleton.every "#{min_cycle_time}s", :tag => 'periodic_hanlon_tasks' do
              begin
                engine = ProjectHanlon::Engine.instance
                engine.remove_expired_nodes(node_timeout)
              rescue java.lang.IllegalStateException => e
                #puts "At 1...#{e.message}"
                logger.error "At 1...#{e.message}"
              end
            end
          end

          # check to make sure there isn't already a 'track_hanlon_tasks' thread
          # running; if there is, then skip this step
          if Rufus::Scheduler.singleton.jobs(:tag => 'track_hanlon_tasks')
            # start a thread to monitor the Hanlon-related tasks we just started (above)
            puts ">> Starting new thread to print status of Hanlon-related jobs..."
            logger.debug ">> Starting new thread to print status of Hanlon-related jobs..."

            Rufus::Scheduler.singleton.every "5m", :tag => 'track_hanlon_tasks' do
              begin
                job_ids = Rufus::Scheduler.singleton.jobs(:tag => 'periodic_hanlon_tasks').map{ |job| job.id }
                puts "  >> At #{Time.now}; Hanlon-related jobs running => [#{job_ids.join(', ')}]"
                logger.debug "  >> At #{Time.now}; Hanlon-related jobs running => [#{job_ids.join(', ')}]"
              rescue java.lang.IllegalStateException => e
                #puts "At 2...#{e.message}"
                logger.error "At 2...#{e.message}"
              end
            end

            # collect together jobs that are running and print out their IDs
            job_ids = Rufus::Scheduler.singleton.jobs(:tag => 'periodic_hanlon_tasks').map { |job| job.id }
            job_ids.push *(Rufus::Scheduler.singleton.jobs(:tag => 'track_hanlon_tasks').map { |job| job.id })
            puts "  >> At #{Time.now}; All jobs running => [#{job_ids.join(', ')}]"
            logger.debug "  >> At #{Time.now}; All jobs running => [#{job_ids.join(', ')}]"
          end
        rescue java.lang.IllegalStateException => e
          #puts "At 3...#{e.message}"
          logger.error "At 3...#{e.message}"
        end
      end

    end
  end
end
