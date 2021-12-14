module ResoTransport
  class ResourceError < StandardError
    attr_reader :resource

    def initialize(resource)
      @resource = resource
      super message
    end

    def resource_name
      return resource.name if resource.respond_to?(:name)

      resource || 'unknown'
    end

    def message
      "Request error for #{resource_name}"
    end
  end

  class EncodeError < ResourceError
    def initialize(resource, property)
      @property = property
      super resource
    end

    def message
      "Property #{@property} not found for #{resource_name}"
    end
  end

  class LocalizationRequired < ResourceError
    def message
      "Localization required for #{resource_name}"
    end
  end

  class RequestError < ResourceError
    attr_reader :request, :response

    def initialize(request, response, resource = nil)
      @response = response.respond_to?(:to_hash) ? response.to_hash : response
      @request = request
      super resource
    end

    def message
      "Received #{response[:status]} for #{resource_name}"
    end
  end

  class NoResponse < RequestError
    def message
      "No response for #{resource_name}"
    end
  end

  class ResponseError < RequestError
    def message
      "Request succeeded for #{resource_name} with response errors"
    end
  end

  class AccessDenied < RequestError
    def initialize(request, response, resource = nil)
      @reason = response.reason_phrase
      super(request, response, resource)
    end

    def message
      "Access denied: #{@reason}"
    end
  end
end
