require 'active_record/implicit_connection_forbidden_error'

module ActiveRecordConnectionOverride
  def connection(*args, &block)
    if Thread.current[:active_record_forbid_implicit_connections] &&
      !connection_handler.retrieve_connection_pool(connection_specification_name).active_connection?
      raise ActiveRecord::ImplicitConnectionForbiddenError.new
    end
    super
  end
end
