class ManifestContentToJson < ActiveRecord::Migration[7.0]
  def up
    Manifest.all.each do |manifest|
      return if manifest.content.is_a? Hash
      manifest.update!(content: jsonify_content(manifest.id, manifest.content))
    end
  end

  def down
    Manifest.all.each do |manifest|
      return if manifest.content.is_a? String
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
