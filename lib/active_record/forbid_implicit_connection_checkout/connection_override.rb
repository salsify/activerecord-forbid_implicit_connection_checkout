# frozen_string_literal: true

require 'active_record/implicit_connection_forbidden_error'

module ActiveRecord
  module ForbidImplicitConnectionCheckout
    module ConnectionOverride
      def connection(...)
        forbid_implicit_connection_checkout!
        super
      end

      # Active Record leases connections for its own queries through the class level
      # `lease_connection` and `with_connection`, so guarding `connection` alone never sees an
      # ordinary query. The pool level `ConnectionPool#with_connection` and `#checkout` are
      # deliberately left alone: they are the documented way for a thread to opt back in.
      def lease_connection(...)
        forbid_implicit_connection_checkout!
        super
      end

      def with_connection(...)
        forbid_implicit_connection_checkout!
        super
      end

      private

      def forbid_implicit_connection_checkout!
        return unless Thread.current[:active_record_forbid_implicit_connections]
        return if connection_handler.retrieve_connection_pool(connection_specification_name).active_connection?

        raise ActiveRecord::ImplicitConnectionForbiddenError.new
      end
    end
  end
end
