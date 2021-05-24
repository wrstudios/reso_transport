module ResoTransport
  Query = Struct.new(:resource) do
    def all(*_contexts, &block)
      new_query_context('and')
      instance_eval(&block)
      clear_query_context
      self
    end

    def any(&block)
      new_query_context('or')
      instance_eval(&block)
      clear_query_context
      self
    end

    %i[eq ne gt ge lt le].each do |op|
      define_method(op) do |conditions|
        conditions.each_pair do |k, v|
          current_query_context << "#{k} #{op} #{encode_value(k, v)}"
        end
        return self
      end
    end

    def limit(size)
      options[:top] = size
      self
    end

    def offset(size)
      options[:skip] = size
      self
    end

    def order(field, dir = nil)
      options[:orderby] = [field, dir].join(' ').strip
      self
    end

    def include_count
      options[:count] = true
      self
    end

    def select(*fields)
      os = options.fetch(:select, '').split(',')
      options[:select] = (os + Array(fields)).uniq.join(',')

      self
    end

    def expand(*names)
      ex = options.fetch(:expand, '').split(',')
      options[:expand] = (ex + Array(names)).uniq.join(',')

      self
    end

    def count
      limit(1).include_count
      parsed = handle_response response
      parsed.fetch('@odata.count', 0)
    end

    def results
      parsed = handle_response response

      results = Array(parsed.delete('value'))
      resource.parse(results)
    end

    def response
      resource.get(compile_params)
    rescue Faraday::ConnectionFailed
      raise NoResponse.new(resource.request, nil, resource)
    end

    def handle_response(response)
      raise RequestError.new(resource.request, response, resource) unless response.success?

      parsed = JSON.parse(response.body)
      raise ResponseError.new(resource.request, response, resource) if parsed.key?('error')

      parsed
    end

    def new_query_context(context)
      @last_query_context ||= 0
      @current_query_context = @last_query_context + 1
      sub_queries[@current_query_context][:context] = context
    end

    def clear_query_context
      @last_query_context = @current_query_context
      @current_query_context = nil
    end

    def current_query_context
      @current_query_context ||= nil
      sub_queries[@current_query_context || :global][:criteria]
    end

    def options
      @options ||= {}
    end

    def sub_queries
      @sub_queries ||= Hash.new { |h, k| h[k] = { context: 'and', criteria: [] } }
    end

    def compile_filters
      groups = sub_queries.dup
      global = groups.delete(:global)
      filter_groups = groups.values

      filter_chunks = []

      filter_chunks << global[:criteria].join(" #{global[:context]} ") if global && global[:criteria]&.any?

      filter_chunks << filter_groups.map do |g|
        "(#{g[:criteria].join(" #{g[:context]} ")})"
      end.join(' and ')

      filter_chunks.reject { |c| c == '' }.join(' and ')
    end

    def compile_params
      params = {}

      options.each_pair do |k, v|
        params["$#{k}"] = v
      end

      params['$filter'] = compile_filters unless sub_queries.empty?

      params
    end

    def encode_value(key, val)
      field = resource.property(key.to_s)
      raise EncodeError.new(resource, key) if field.nil?

      field.encode(val)
    end
  end
end
