class DataOnlyUpdateJsonValues < ActiveRecord::Migration[6.0]

  def jsonParseWithCatch(ref, val)
    begin
      return if val.blank?
      return JSON.parse(val)
    rescue => e
      puts "[DataOnlyUpdateJsonValues] Could not transform #{ref}, #{e}"
    end
    return val
  end

  def stringifyWithCatch(ref, val)
    begin
      return if val.blank?
      return val.to_json
    rescue => e
      puts "[DataOnlyUpdateJsonValues] Could not transform #{ref}, #{e}"
    end
    return val
  end

  def up
    Manifest.all.each do |manifest|
      manifest.content = jsonParseWithCatch("Manifest #{manifest.id}", manifest.content)
      manifest.save
    end
    Webhook.all.each do |webhook|
      webhook.payload = jsonParseWithCatch("Webhook #{webhook.id}", webhook.payload)
      webhook.diagnostics = jsonParseWithCatch("Webhook #{webhook.id}", webhook.diagnostics)
      webhook.save
    end
  end

  def down
    Manifest.all.each do |manifest|
      manifest.content = stringifyWithCatch("Manifest #{manifest.id}", manifest.content)
      manifest.save
    end
    Webhook.all.each do |webhook|
      webhook.payload = stringifyWithCatch("Webhook #{webhook.id}", webhook.payload)
      webhook.diagnostics = stringifyWithCatch("Webhook #{webhook.id}", webhook.diagnostics)
      webhook.save
    end
  end

end
