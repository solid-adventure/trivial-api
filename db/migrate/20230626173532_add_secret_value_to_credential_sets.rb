class AddSecretValueToCredentialSets < ActiveRecord::Migration[6.1]
  def change
    add_column :credential_sets, :secret_value, :text
  end
end
