module Committee::Middleware
  class ResponseValidation < Base
    def initialize(app, options={})
      super
      @validate_errors = options[:validate_errors]
    end

    def handle(request)
      status, headers, response = @app.call(request.env)

      if validate?(status) && link = @router.find_request_link(request)
        full_body = ""
        response.each do |chunk|
          full_body << chunk
        end
        data = MultiJson.decode(full_body)
        Committee::ResponseValidator.new(link).call(status, headers, data)
      end

      [status, headers, response]
    rescue Committee::InvalidResponse
      raise if @raise
      @error_class.new(500, :invalid_response, $!.message).render
    rescue MultiJson::LoadError
      raise Committee::InvalidResponse if @raise
      @error_class.new(500, :invalid_response, "Response wasn't valid JSON.").render
    end

    def validate?(status)
      Committee::ResponseValidator.validate?(status)
    end
  end
end
