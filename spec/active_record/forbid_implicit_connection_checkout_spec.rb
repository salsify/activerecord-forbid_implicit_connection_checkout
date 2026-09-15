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

  # Active Record leases connections for its own queries through the class level
  # `lease_connection` and `with_connection`, not through `connection`, so these are the paths
  # an ordinary query actually takes.
  describe "the paths Active Record itself uses" do
    it "prevents an implicit lease_connection" do
      expect do
        t = Thread.new do
          ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
          ActiveRecord::Base.lease_connection.select_value('SELECT 1')
        end
        t.join
      end.to raise_error(ActiveRecord::ImplicitConnectionForbiddenError)
    end

    it "prevents an implicit with_connection" do
      expect do
        t = Thread.new do
          ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
          ActiveRecord::Base.with_connection { |connection| connection.select_value('SELECT 1') }
        end
        t.join
      end.to raise_error(ActiveRecord::ImplicitConnectionForbiddenError)
    end

    it "prevents a read issued through a model" do
      expect do
        t = Thread.new do
          ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
          ImplicitCheckoutWidget.count
        end
        t.join
      end.to raise_error(ActiveRecord::ImplicitConnectionForbiddenError)
    end

    it "prevents a write issued through a model" do
      expect do
        t = Thread.new do
          ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
          ImplicitCheckoutWidget.create!(name: 'widget')
        end
        t.join
      end.to raise_error(ActiveRecord::ImplicitConnectionForbiddenError)
    end

    it "allows them inside a manual pool checkout" do
      t = Thread.new do
        ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
        ActiveRecord::Base.connection_pool.with_connection do
          [
            ActiveRecord::Base.with_connection { |connection| connection.select_value('SELECT 1') },
            ImplicitCheckoutWidget.count
          ]
        end
      end
      t.join
      expect(t.value).to eq([1, 0])
    end

    it "allows lease_connection inside a manual pool checkout" do
      t = Thread.new do
        ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
        value = ActiveRecord::Base.connection_pool.with_connection do
          ActiveRecord::Base.lease_connection.select_value('SELECT 1')
        end
        ActiveRecord::Base.connection_pool.release_connection
        value
      end
      t.join
      expect(t.value).to eq(1)
    end

    it "does not affect a thread that has not forbidden checkout" do
      t = Thread.new do
        value = ImplicitCheckoutWidget.count
        ActiveRecord::Base.connection_pool.release_connection
        value
      end
      t.join
      expect(t.value).to eq(0)
    end
  end
end
