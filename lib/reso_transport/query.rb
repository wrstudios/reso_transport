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
          current_query_context.push "#{k} #{op} #{encode_value(k, v)}"
        end
        return self
      end
    end

    def set_query_params(params)
      query_parameters.merge!(params)
      self
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

    def page(token)
      options[:next] = token
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
      @next_link = parsed.fetch('@odata.nextLink', nil)
      results = Array(parsed.delete('value'))
      resource.parse(results)
    end

    # Can only be accessed after results call or if it's being set
    def next_link
      @next_link
    end

    # used for setting the next_link with trestle's replication strategy
    def next_link=(link)
      @next_link = link
    end

    private

    def response
      use_next_link? ? resource.get_next_link_results(next_link) : resource.get(compile_params)
    rescue Faraday::ConnectionFailed
      raise NoResponse.new(resource.request, nil, resource)
    end

    def use_next_link?
      compile_params[:replication] && !next_link.nil?
    end

    def handle_response(response)
      raise RequestError.new(resource.request, response, resource) unless response.success?

      parsed = JSON.parse(response.body)
      raise ResponseError.new(resource.request, response, resource) if parsed.key?('error')

      parsed
    end

    def options
      @options ||= {}
    end

    def query_parameters
      @query_parameters ||= {}
    end

    def sub_queries
      @sub_queries ||= [SubQuery.new("and")]
    end

    def new_query_context(context)
      @last_query_context_index ||= 0
      @current_query_context_index = @last_query_context_index + 1
      sub_queries[@current_query_context_index] = SubQuery.new(context, parens: true)
    end

    def clear_query_context
      @last_query_context_index = @current_query_context_index
      @current_query_context_index = nil
    end

    def current_query_context
      sub_queries[@current_query_context_index || 0]
    end

    class SubQuery
      def initialize context, criteria=[], parens: false
        @context = context
        @parens = parens
        @criteria = criteria
      end

      attr_reader :context, :parens, :criteria
      alias_method :parens?, :parens

      def to_s
        out = criteria.select { |x| x.length > 0 }.map(&:to_s).join(" #{context} ")
        out = "(#{out})" if parens?
        out
      end

      def push x
        criteria << x
      end
      alias_method :<<, :push

      def length
        criteria.length
      end

      def present?
        length > 0
      end
    end

    def compile_filters
      global, *filter_groups = sub_queries
      SubQuery.new("and", [
        global,
        SubQuery.new("and", filter_groups),
      ]).to_s
    end

    public def compile_params
      params = {}

      options.each_pair do |k, v|
        params["$#{k}"] = v
      end

      params['$filter'] = compile_filters if sub_queries.any?(&:present?)
      params.merge!(query_parameters) unless query_parameters.empty?

      params
    end

    def encode_value(key, val)
      field = resource.property(key.to_s)
      raise EncodeError.new(resource, key) if field.nil?

      field.encode(val)
    end
  end
end
