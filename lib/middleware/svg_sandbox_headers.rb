# frozen_string_literal: true

module Middleware
  # SVGs served directly from disk (e.g. the canonical
  # `/uploads/.../original/1X/<sha>.svg` path) are handled by
  # `ActionDispatch::Static` and never pass through `UploadsController`, so
  # they miss the `Content-Security-Policy: sandbox;` header that controller
  # applies to every other upload response. Without it, any CSS or markup
  # smuggled into a stored SVG's `<style>` element can still be used to
  # execute/exfiltrate when the browser renders it inline.
  #
  # This middleware runs after `ActionDispatch::Static` so it can add the
  # header to any response Rack ends up serving as `image/svg+xml`,
  # regardless of whether it went through a controller.
  class SvgSandboxHeaders
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      content_type = headers["Content-Type"]

      if content_type&.include?("image/svg+xml") && !headers["Content-Security-Policy"]
        headers["Content-Security-Policy"] = "sandbox;"
      end

      [status, headers, body]
    end
  end
end
