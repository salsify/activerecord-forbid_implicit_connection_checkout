# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'logger'
require 'active_record'
require 'active_record-forbid_implicit_connection_checkout'
require 'fileutils'
require 'yaml'
require 'database_cleaner'
require 'pg'

FileUtils.makedirs('log')

ActiveRecord::Base.logger = Logger.new('log/test.log')
ActiveRecord::Base.logger.level = Logger::DEBUG
ActiveRecord::Migration.verbose = false

database_host = ENV.fetch('DB_HOST', 'localhost')
database_port = ENV.fetch('DB_PORT', 5432)
database_user = ENV.fetch('DB_USER', 'postgres')
database_password = ENV.fetch('DB_PASSWORD', 'password')
database_url = "postgres://#{database_user}:#{database_password}@#{database_host}:#{database_port}"
admin_database_name = "/#{ENV['ADMIN_DB_NAME']}" if ENV['ADMIN_DB_NAME'].present?

DATABASE_NAME = 'forbid_implicit_connection_checkout_test'

def setup_test_database(pg_conn, database_name)
  pg_conn.exec("DROP DATABASE IF EXISTS #{database_name}")
  pg_conn.exec("CREATE DATABASE #{database_name}")

  pg_version = pg_conn.exec('SELECT version()')
  puts "Testing with Postgres version: #{pg_version.getvalue(0, 0)}"
  puts "Testing with ActiveRecord #{ActiveRecord::VERSION::STRING}"
end

def teardown_test_database(pg_conn, database_name)
  pg_conn.exec("DROP DATABASE IF EXISTS #{database_name}")
end

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    PG::Connection.open("#{database_url}#{admin_database_name}") do |connection|
      setup_test_database(connection, DATABASE_NAME)
    end

    ActiveRecord::Base.establish_connection("#{database_url}/#{DATABASE_NAME}")

    DatabaseCleaner.strategy = :transaction
  end

  config.after(:suite) do
    ActiveRecord::Base.connection_pool.disconnect!

    PG::Connection.open("#{database_url}#{admin_database_name}") do |connection|
      teardown_test_database(connection, DATABASE_NAME)
    end
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
