namespace :elasticsearch do
  desc "Create Elasticsearch indices (skips gracefully if ES is unreachable)"
  task create_indices: :environment do
    Elasticsearch::CandidateResultIndexer.create_index!
    puts "Elasticsearch index created: #{ENV.fetch('ELASTICSEARCH_INDEX_NAME', 'candidate_results')}"
  rescue Faraday::ConnectionFailed, Errno::ECONNREFUSED => e
    puts "WARN: Elasticsearch not reachable (#{e.message}). Index creation skipped."
    puts "      Run this task again once Elasticsearch is running."
  end

  desc "Reindex all existing results in batches (skips gracefully if ES is unreachable)"
  task reindex: :environment do
    Rake::Task["elasticsearch:create_indices"].invoke

    count = 0
    Result.includes(:assessment, candidate_session: :invitation).find_in_batches(batch_size: 100) do |batch|
      Elasticsearch::CandidateResultIndexer.bulk_index_results(batch)
      count += batch.size
      puts "  indexed #{count} results..."
    end
    puts "Reindexing complete — #{count} results indexed."
  rescue Faraday::ConnectionFailed, Errno::ECONNREFUSED => e
    puts "WARN: Elasticsearch not reachable (#{e.message}). Reindex skipped."
  end

  desc "Check Elasticsearch connection"
  task ping: :environment do
    client = Elasticsearch::Model.client
    info   = client.info
    puts "Elasticsearch OK — version #{info.dig('version', 'number')}"
  rescue => e
    puts "Elasticsearch UNREACHABLE — #{e.message}"
    exit 1
  end
end
