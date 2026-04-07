namespace :elasticsearch do
  desc "Create Elasticsearch indices"
  task create_indices: :environment do
    Elasticsearch::CandidateResultIndexer.create_index!
    puts "Elasticsearch index created"
  end

  desc "Reindex all results"
  task reindex: :environment do
    Rake::Task["elasticsearch:create_indices"].invoke
    Result.includes(:assessment, candidate_session: :invitation).find_in_batches(batch_size: 100) do |batch|
      Elasticsearch::CandidateResultIndexer.bulk_index_results(batch)
    end
    puts "Reindexing complete"
  end
end
