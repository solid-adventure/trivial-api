class AddHostnameFieldsToApps < ActiveRecord::Migration[6.0]
  class App < ActiveRecord::Base
  end

  def up
    add_column :apps, :hostname, :string
    add_column :apps, :domain, :string
    add_column :apps, :load_balancer, :string

    App.where(hostname: nil).update_all('hostname = LOWER(name)')
    App.where(domain: nil).update_all(domain: 'staging.trivialapps.io')
    App.where(load_balancer: nil).update_all(load_balancer: 'staging-lb')

    change_column_null(:apps, :hostname, false)
    change_column_null(:apps, :domain, false)
    change_column_null(:apps, :load_balancer, false)
  end

  def down
    remove_column :apps, :hostname, :string
    remove_column :apps, :domain, :string
    remove_column :apps, :load_balancer, :string
  end
end
