Elasticsearch::Model.client = Elasticsearch::Client.new(
  url: ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200"),
  transport_options: { request: { timeout: 5 } },
  log: Rails.env.development?
)
