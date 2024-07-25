class CreateCharts < ActiveRecord::Migration[7.0]
  def change
    create_table :charts do |t|
      t.references :dashboard, null: false, foreign_key: true
      t.references :register, null: false, foreign_key: true
      t.string :name, null: false
      t.string :chart_type, null: false, default: 'gross_revenue'
      t.string :color_scheme, null: false, default: 'default'
      t.string :report_period, null: false
      t.boolean :meta0
      t.boolean :meta1
      t.boolean :meta2
      t.boolean :meta3
      t.boolean :meta4
      t.boolean :meta5
      t.boolean :meta6
      t.boolean :meta7
      t.boolean :meta8
      t.boolean :meta9

      t.timestamps
    end
    add_index :charts, :chart_type

    default_charts = []
    Register.all.each do |register|
      next unless register.owner_type == 'Organization'
      default_charts.push(
        {
          dashboard_id: register.owner.owned_dashboards.first.id,
          register_id: register.id,
          name: "Gross Revenue",
          report_period: 'month',
          meta0: register.meta.key?('meta0') ? false : nil,
          meta1: register.meta.key?('meta1') ? false : nil,
          meta2: register.meta.key?('meta2') ? false : nil,
          meta3: register.meta.key?('meta3') ? false : nil,
          meta4: register.meta.key?('meta4') ? false : nil,
          meta5: register.meta.key?('meta5') ? false : nil,
          meta6: register.meta.key?('meta6') ? false : nil,
          meta7: register.meta.key?('meta7') ? false : nil,
          meta8: register.meta.key?('meta8') ? false : nil,
          meta9: register.meta.key?('meta9') ? false : nil,
        }
      )
    end
    Chart.insert_all(default_charts)
  end
end
