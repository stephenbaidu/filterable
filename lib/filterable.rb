require "filterable/version"

module Filterable
  module Filter
    extend ActiveSupport::Concern

    included do
      scope :filter, -> (filters = {}) { filterable(filters) }
    end

    module ClassMethods
      private

      def filterable(filters)
        simple_ops = { eq: '=', lt: '<', gt: '>', lte: '<=', gte: '>=', ne: '!='}

        query_klass = where(nil)

        filters.each do |key, value|
          next unless value.present?

          field, op = key.split('.')
          next unless columns_hash[field]

          if simple_ops[op]
            query_klass = query_klass.where("#{field} #{simple_ops[op.to_sym]} ?", value)
          elsif op == 'in'
            query_klass = query_klass.where("#{field} IN (?)", value.split(','))
          elsif op == 'like'
            like_token = (ActiveRecord::Base.connection.adapter_name == "PostgreSQL")? 'ILIKE' : 'LIKE'
            query_klass = query_klass.where("#{field} #{like_token} ?", "%#{value}%")
          elsif field.present?
            query_klass = query_klass.where("#{field} = ?", value)
          end
        end

        query_klass
      end
    end
  end
end
