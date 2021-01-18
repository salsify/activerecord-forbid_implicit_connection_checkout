# frozen_string_literal: true

# This is needed because of https://github.com/rails/rails/blob/5-0-stable/activerecord/lib/active_record/errors.rb#L221
require 'active_model/errors'
require 'active_record/errors'

module ActiveRecord
  class ImplicitConnectionForbiddenError < ActiveRecord::ConnectionNotEstablished
    MESSAGE = 'Implicit ActiveRecord checkout attempted when Thread :active_record_forbid_implicit_connections set!'

    def initialize
      super(MESSAGE)
    end
  end
end
