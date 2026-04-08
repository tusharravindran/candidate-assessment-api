Elasticsearch::Model.client = Elasticsearch::Client.new(
  url: ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200"),
  transport_options: { request: { timeout: 5 } },
  log: Rails.env.development?
)

# OpenSearch (Bonsai) does not return Elasticsearch product headers, so allow
# disabling the product check when explicitly configured.
if ENV.fetch("ELASTICSEARCH_SKIP_PRODUCT_CHECK", "false") == "true"
  Elasticsearch::Client.class_eval do
    private

    def verify_elasticsearch
      @verified = true
    end
  end
end
