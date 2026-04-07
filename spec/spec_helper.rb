RSpec.configure do |config|
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
