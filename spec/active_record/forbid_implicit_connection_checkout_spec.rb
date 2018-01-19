describe ActiveRecord::ForbidImplicitConnectionCheckout do
  it "has a version number" do
    expect(ActiveRecord::ForbidImplicitConnectionCheckout::VERSION).not_to be nil
  end

  let(:thread_return_value) { 12345 }

  context "prevents implicit checkout" do
    around do |example|
      original_value = Thread.report_on_exception
      Thread.report_on_exception = false
      example.run
      Thread.report_on_exception = original_value
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
end
