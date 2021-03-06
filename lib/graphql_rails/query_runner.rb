# frozen_string_literal: true

module GraphqlRails
  # executes GraphQL queries and returns json
  class QueryRunner
    require 'graphql_rails/router'
    require 'graphql_rails/concerns/service'

    include ::GraphqlRails::Service

    def initialize(group: nil, params:, schema: nil, router: nil, **schema_options)
      @group = group
      @graphql_schema = schema
      @params = params
      @schema_options = schema_options
      @router = router
    end

    def call
      graphql_schema.execute(
        params[:query],
        variables: variables,
        operation_name: params[:operationName],
        **schema_options
      )
    end

    private

    attr_reader :schema_options, :params, :group

    def variables
      ensure_hash(params[:variables])
    end

    def graphql_schema
      @graphql_schema ||= router_schema
    end

    def router
      @router ||= ::GraphqlRouter
    end

    def router_schema
      router.graphql_schema(group)
    end

    def ensure_hash(ambiguous_param)
      if ambiguous_param.blank?
        {}
      elsif ambiguous_param.is_a?(String)
        ensure_hash(JSON.parse(ambiguous_param))
      elsif kind_of_hash?(ambiguous_param)
        ambiguous_param
      else
        raise ArgumentError, "Unexpected parameter: #{ambiguous_param.inspect}"
      end
    end

    def kind_of_hash?(object)
      return true if object.is_a?(Hash)

      defined?(ActionController) &&
        defined?(ActionController::Parameters) &&
        object.is_a?(ActionController::Parameters)
    end
  end
end
