module ForbidImplicitConnectionCheckoutForThread
  extend ActiveSupport::Concern

  module ClassMethods
    def forbid_implicit_connection_checkout_for_thread!
      Thread.current[:active_record_forbid_implicit_connections] = true
    end
  end
end
