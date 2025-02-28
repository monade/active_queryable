# frozen_string_literal: true

require 'active_support/concern'
require 'active_record'
require 'kaminari/activerecord'

# A light and simple gem for sorting / filtering / paginating a model in Rails.
module ActiveQueryable
  extend ActiveSupport::Concern

  # @private
  QUERYABLE_VALID_PARAMS = %i[filter sort page per].freeze

  included do
    class_attribute :_queryable_default_order
    class_attribute :_queryable_default_page
    class_attribute :_queryable_default_per
    class_attribute :_queryable_filter_keys
    class_attribute :_queryable_expandable_filter_keys
  end

  # @private
  module Initializer
    # Enables ActiveQueryable for the model
    # @example
    #   class User < ApplicationRecord
    #     as_queryable
    #   end
    #
    # @!parse include ActiveQueryable
    # @return [void]
    def as_queryable
      send :include, ActiveQueryable
    end
  end

  # Extension methods for ActiveRecord::Base
  # @!method query_by(params)
  #   Runs a query with the given params
  #   @example
  #     User.query_by(sort: '-name', filter: { name: 'John' })
  #   @param params [Hash,ActionController::Parameters]
  #   @option params [String] :sort
  #   @option params [Hash] :filter
  #   @option params [String] :page
  #   @option params [String] :per
  #   @option params [Hash] :page
  #   @return [ActiveRecord::Relation]
  # @!method of_not(ids)
  #   @example
  #     User.of_not([1, 2, 3]) # => equivalent of: User.where.not(id: [1, 2, 3])
  #   Returns a scope with the given ids excluded
  #   @param ids [Array<Integer,String>]
  #   @return [ActiveRecord::Relation]
  module ClassMethods
    # Configures the model to be queryable
    # @example
    #   class User < ApplicationRecord
    #     as_queryable
    #     queryable order: { name: :asc }, page: 1, per: 25, filter: %i[name email]
    #   end
    #
    # @param options [Hash]
    # @option options [Hash<Symbol,Symbol>] :order { id: :asc }
    # @option options [Integer] :page 1
    # @option options [Integer] :per 25
    # @option options [Array<Symbol,String>] :filter []
    # @return [void]
    def queryable(options)
      queryable_configure_options(options)

      scope :query_by, ->(params) { queryable_scope(params) }
      scope :of_ids, ->(ids) { where(id: ids) }
      scope :of_not, ->(ids) { where.not(id: ids) }
    end

    # A method to expand the filterable keys, useful to allow class inheritance
    # @example
    #   class BaseItem < ApplicationRecord
    #     as_queryable
    #     queryable order: { name: :asc }, page: 1, per: 25, filter: %i[name email]
    #   end
    #   class AdvancedItem < BaseItem
    #     expand_queryable filter: %i[phone]
    #   end
    #
    #
    # @param options [Hash]
    # @option options [Array<Symbol,String>] :filter []
    # @return [void]
    def expand_queryable(options)
      self._queryable_expandable_filter_keys ||= []
      self._queryable_expandable_filter_keys += (options[:filter] || []).map(&:to_sym)
    end

    # @param params [Hash,ActionController::Parameters]
    # @option params [String] :sort
    # @option params [Hash] :filter
    # @option params [String] :page
    # @option params [String] :per
    # @option params [Hash] :page
    # @return [ActiveRecord::Relation]
    def queryable_scope(params)
      params = params.to_unsafe_h if params.respond_to? :to_unsafe_h
      params = params.with_indifferent_access if params.respond_to?(:with_indifferent_access)
      queryable_log_unpermitted_params(params)

      order_params = queryable_validate_order_params(params[:sort])
      query = queryable_parse_order_scope(order_params, self)

      queryable_filtered_scope(params, query)
    end

    private

    # @param params [Hash,ActionController::Parameters]
    # @return [void]
    def queryable_log_unpermitted_params(params)
      params.each_key do |k|
        next if QUERYABLE_VALID_PARAMS.include?(k.to_sym)

        Rails.logger.debug(
          "Unsupported key `#{k}` passed to `query_by` will be ignored. Allowed keys: #{QUERYABLE_VALID_PARAMS.join(', ')}"
        )
      end
    end

    # @option options [Hash<Symbol,Symbol>] :order { id: :asc }
    # @option options [Integer] :page 1
    # @option options [Integer] :per 25
    # @option options [Array<Symbol,String>] :filter []
    # @return [void]
    def queryable_configure_options(options)
      self._queryable_default_order = options[:order] || { id: :asc }
      self._queryable_default_page = options[:page] || 1
      self._queryable_default_per = options[:per] || 25
      self._queryable_filter_keys = ((options[:filter] || []).map(&:to_sym))
    end

    # @param params [Hash,ActionController::Parameters]
    # @option params [String] :sort
    # @option params [Hash] :filter
    # @option params [String] :page
    # @option params [String] :per
    # @option params [Hash] :page
    # @param query [ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    def queryable_filtered_scope(params, query)
      filter_params = queryable_validate_filter_params(params[:filter])

      page_params = queryable_validate_page_params(params)

      scope = queryable_parse_filter_scope(filter_params, query)

      unless page_params[:per] == 'all'
        scope = scope
                .page(page_params[:page])
                .per(page_params[:per])
      end

      scope
    end

    # @param params [String,nil]
    # @return [Hash]
    def queryable_validate_order_params(params)
      queryable_parse_order_params(params) || _queryable_default_order
    end

    # @param params [Hash,ActionController::Parameters]
    # @option params [String] :page
    # @option params [String] :per
    # @option params [Hash] :page
    # @return [Hash]
    def queryable_validate_page_params(params)
      page_params = {}
      if params[:page].respond_to?(:dig)
        page_params[:page] = params.dig(:page, :number) || _queryable_default_page
        page_params[:per] = params.dig(:page, :size) || _queryable_default_per
      else
        page_params[:page] = params[:page] || _queryable_default_page
        page_params[:per] = params[:per] || _queryable_default_per
      end
      page_params
    end

    # @param filter_params [Hash,ActionController::Parameters,nil]
    # @return [Hash]
    def queryable_validate_filter_params(filter_params)
      return nil if filter_params.nil?

      filters = (((_queryable_filter_keys || []) | (self._queryable_expandable_filter_keys || [])) + ['not']).map(&:to_sym)
      unpermitted = filter_params.except(*filters)
      Rails.logger.warn("Unpermitted queryable parameters: #{unpermitted.keys.join(', ')}") if unpermitted.present?

      filter_params.slice(*filters)
    end

    # @param params [String,nil]
    # @return [Hash]
    def queryable_parse_order_params(params)
      return nil unless params.is_a? String

      params.split(',').map! do |param|
        clean_param = param.start_with?('-') ? param[1..-1] : param
        [clean_param, clean_param == param ? :asc : :desc]
      end.to_h
    end

    # @param params [Hash,ActionController::Parameters,nil]
    # @param query [ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    def queryable_parse_order_scope(params, query)
      return query unless params

      params.inject(query) do |current_query, (k, v)|
        scope = "by_#{k}"

        if current_query.respond_to?(scope, true)
          current_query.public_send(scope, v)
        else
          current_query.order(params)
        end
      end || query
    end

    # @param params [Hash,ActionController::Parameters,nil]
    # @param query [ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    def queryable_parse_filter_scope(params, query)
      return query unless params

      params.inject(query) do |current_query, (k, v)|
        scope = "of_#{k}"

        if current_query.respond_to?(scope, true)
          current_query.public_send(scope, v)
        else
          current_query.where(k => v)
        end
      end
    end
  end
end

# rubocop:disable Lint/SendWithMixinArgument
ActiveRecord::Base.send(:extend, ActiveQueryable::Initializer)
# rubocop:enable Lint/SendWithMixinArgument
