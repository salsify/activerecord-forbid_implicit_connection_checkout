# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'active_record'
require 'active_record-forbid_implicit_connection_checkout'
require 'fileutils'
require 'logger'
require 'yaml'
require 'database_cleaner'

FileUtils.makedirs('log')

ActiveRecord::Base.logger = Logger.new('log/test.log')
ActiveRecord::Base.logger.level = Logger::DEBUG
ActiveRecord::Migration.verbose = false

db_adapter = ENV.fetch('ADAPTER', 'postgresql')
db_config = YAML.safe_load(File.read('spec/db/database.yml'))
db_host = db_config[db_adapter]['host']
ENV['PGHOST'] ||= db_host if db_host

DATABASE_NAME = 'forbid_implicit_connection_checkout_test'

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    `dropdb --if-exists #{DATABASE_NAME}`
    `createdb #{DATABASE_NAME}`

    ActiveRecord::Base.establish_connection(db_config[db_adapter])

    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
