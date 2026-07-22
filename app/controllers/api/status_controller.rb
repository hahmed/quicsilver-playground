module Api
  class StatusController < ApplicationController
    def show
      render json: {
        ok: true,
        app: "quicsilver-playground",
        rails: Rails.version,
        ruby: RUBY_VERSION,
        protocol: request.protocol,
        server_protocol: request.env["SERVER_PROTOCOL"],
        http_version: request.env["HTTP_VERSION"],
        request_method: request.request_method,
        path: request.path,
        at: Time.current.iso8601
      }
    end
  end
end
