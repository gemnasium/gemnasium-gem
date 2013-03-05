require 'gemnasium'
require 'gemnasium/options'
require 'rspec'
require 'webmock/rspec'
# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

WebMock.disable_net_connect!