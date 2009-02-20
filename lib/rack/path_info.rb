module Rack
  class PathInfo
    def initialize(app)
      @app = app
    end
    def call(env)
      env['PATH_INFO'] ||= env['REQUEST_URI'].sub(/\?.*$/, '')
      @app.call(env)
    end
  end
end
