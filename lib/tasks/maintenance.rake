namespace :maintenance do
  desc "Delete expired manifest drafts"
  task cleanup_drafts: :environment do
    ManifestDraft.expired.delete_all
  end
end
