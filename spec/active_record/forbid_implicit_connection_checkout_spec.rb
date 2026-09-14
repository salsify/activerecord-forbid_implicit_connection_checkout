# frozen_string_literal: true

describe ActiveRecord::ForbidImplicitConnectionCheckout do
  let(:thread_return_value) { 12345 }

  before do
    Thread.report_on_exception = false
  end

  it "has a version number" do
    expect(ActiveRecord::ForbidImplicitConnectionCheckout::VERSION).not_to be nil
  end

  it "prevents implicit checkout" do
    expect do
      t = Thread.new do
        ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
        ActiveRecord::Base.connection
      end
      t.join
    end.to raise_error(ActiveRecord::ImplicitConnectionForbiddenError)
  end

  it "allows manual checkout via with_connection" do
    t = Thread.new do
      ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.connection
      end
      thread_return_value
    end
    t.join
    expect(t.value).to eq(thread_return_value)
  end

  it "allows manual checkout via checkout" do
    t = Thread.new do
      ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
      conn = ActiveRecord::Base.connection_pool.checkout
      ActiveRecord::Base.connection_pool.checkin(conn)
      thread_return_value
    end
    t.join
    expect(t.value).to eq(thread_return_value)
  end

  it "returns a usable connection when the thread already holds one" do
    t = Thread.new do
      ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.connection.select_value('SELECT 1')
      end
    end
    t.join
    expect(t.value).to eq(1)
  end

  it "allows the checkout once the thread has leased a connection outside a block" do
    t = Thread.new do
      ActiveRecord::Base.lease_connection
      ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
      value = ActiveRecord::Base.connection.select_value('SELECT 1')
      ActiveRecord::Base.connection_pool.release_connection
      value
    end
    t.join
    expect(t.value).to eq(1)
  end

  it "does not leak the restriction to other threads" do
    forbidden = Thread.new do
      ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
    end
    forbidden.join

    permitted = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.connection.select_value('SELECT 1')
      end
    end
    permitted.join
    expect(permitted.value).to eq(1)
  end

  # Known limitation, unchanged across every supported Rails version.
  #
  # This gem only prepends `ActiveRecord::Base.connection`. Rails 7.2 introduced
  # `lease_connection` / `with_connection` and moved its own internals onto them, so an
  # ordinary query no longer routes through `connection` and is not intercepted. These
  # examples pin the current behaviour so that any future fix has to change them
  # deliberately rather than by accident.
  describe "paths that are not intercepted" do
    it "does not prevent an explicit lease_connection" do
      t = Thread.new do
        ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
        ActiveRecord::Base.lease_connection
        value = ActiveRecord::Base.connection.select_value('SELECT 1')
        ActiveRecord::Base.connection_pool.release_connection
        value
      end
      t.join
      expect(t.value).to eq(1)
    end

    it "does not prevent a query issued through a model" do
      t = Thread.new do
        ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
        value = ImplicitCheckoutWidget.count
        ActiveRecord::Base.connection_pool.release_connection
        value
      end
      t.join
      expect(t.value).to eq(0)
    end
  end
end
