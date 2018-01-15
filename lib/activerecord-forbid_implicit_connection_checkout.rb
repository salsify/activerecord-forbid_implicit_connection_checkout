require 'active_record'
require 'version'
require 'active_record/implicit_connection_forbidden_error'
require 'active_record/forbid_implicit_connection_checkout'
require 'active_record/connection_override'

ActiveRecord::Base.include(ActiveRecord::ForbidImplicitConnectionCheckout)
ActiveRecord::Base.singleton_class.prepend(ActiveRecord::ConnectionOverride)
