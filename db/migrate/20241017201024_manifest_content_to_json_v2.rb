class ManifestContentToJsonV2 < ActiveRecord::Migration[7.0]
  def up
    Manifest.all.each do |manifest|
      if manifest.content.is_a?(Hash)
        Rails.logger.info("skipping manifest id:#{manifest.id}, content is a Hash")
        next
      end
      manifest.update!(content: jsonify_content(manifest.id, manifest.content))
    end
  end

  def down
    Manifest.all.each do |manifest|
      if manifest.content.is_a?(String)
        Rails.logger.info("skipping manifest id:#{manifest.id}, content is a String")
        next
      end
      manifest.update!(content: stringify_content(manifest.id, manifest.content))
    end
  end

  def jsonify_content(id, content)
    return if content.blank?
    JSON.parse(content)
  rescue => e
    puts "Could not transform Manifest #{id}, #{content}"
    content
  end

  def stringify_content(id, content)
    return if content.blank?
    content.to_json
  rescue => e
    puts "Could not transform Manifest #{id}, #{content}"
    content
  end
end
