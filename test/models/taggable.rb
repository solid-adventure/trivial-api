require 'test_helper'

class TaggableTest < ActiveSupport::TestCase
    def setup
      @user = User.create!(name: 'test', email: 'test@example.test', password: 'password')
      @app = App.create(user_id: @user.id, descriptive_name: 'Generic App')
    end
 
    test 'can add tag to App' do
      assert @app.tags.size == 0
      assert @app.addTag!(:currency, 'USD')
      assert @app.tags.first.context == 'currency'
    end

    test 'can remove tag on App' do
      Tag.delete_all
      assert @app.addTag!(:currency, 'USD')
      assert @app.tags.where(context: 'currency', name: 'USD').size == 1
      assert @app.removeTag!(:currency, 'USD')
      assert @app.tags.where(context: 'currency', name: 'USD').size == 0
    end

    test 'adding tags is idempotent' do
      Tag.delete_all
      assert @app.addTag!(:currency, 'USD')
      @p
      assert @app.tags.where(context: 'currency', name: 'USD').size == 1
    end

    test 'removing tags is idempotent' do
      Tag.delete_all
      assert @app.addTag!(:currency, 'USD')
      assert @app.removeTag!(:currency, 'USD')
      assert @app.removeTag!(:currency, 'USD')
      assert @app.tags.where(context: 'currency', name: 'USD').size == 0
    end

    test 'tagged class table_alias_for_tag method interpolates' do
      assert App.table_alias_for_tag({umbrellas: true}) == "umbrellas_tags"
      assert App.table_alias_for_tag({currency: 'USD'}) == "currency_tags"
      assert App.table_alias_for_tag({customer_ids: [1,2,3]}) == "customer_ids_tags"
    end

    test 'joins for tag list produces an array of joins' do
      tag_list = [{currency: 'USD'}, {customer_ids: [1,2,3]}]
      joins = App.joins_for_tags(tag_list)
      assert joins.size == tag_list.size
      assert joins == ["LEFT OUTER JOIN \"tags\" currency_tags\nON \"currency_tags\".\"taggable_type\" = 'App'\nAND \"currency_tags\".\"taggable_id\" = \"apps\".\"id\"\nAND \"currency_tags\".\"context\" = 'currency'\n", "LEFT OUTER JOIN \"tags\" customer_ids_tags\nON \"customer_ids_tags\".\"taggable_type\" = 'App'\nAND \"customer_ids_tags\".\"taggable_id\" = \"apps\".\"id\"\nAND \"customer_ids_tags\".\"context\" = 'customer_ids'\n"]
    end

    test 'where_for_tags produces an array of conditions' do
      tag_list = [{currency: 'USD'}, {customer_ids: [1,2,3]}]
      where = App.where_for_tags(tag_list)
      assert where.size == tag_list.size
    end

    test 'find_by_all_tags returns expected record' do
      @app1 = App.create(user_id: @user.id, descriptive_name: 'USD - customer 1')
      @app1.addTag!(:currency, 'USD')
      @app1.addTag!(:customer_ids, '1')

      @app2 = App.create(user_id: @user.id, descriptive_name: 'USD - customer 2')
      @app2.addTag!(:currency, 'USD')
      @app2.addTag!(:customer_ids, '2')

      @app3 = App.create(user_id: @user.id, descriptive_name: 'CAD - customer 1')
      @app3.addTag!(:currency, 'CAD')
      @app3.addTag!(:customer_ids, '1')

      @app4 = App.create(user_id: @user.id, descriptive_name: 'CAD - customer 2')
      @app4.addTag!(:currency, 'CAD')
      @app4.addTag!(:customer_ids, '2')

      app = App.find_by_all_tags([{currency: 'USD'}, {customer_ids: 1}]).limit(1).first
      assert app.id == @app1.id

      app = App.find_by_all_tags([{currency: 'CAD'}, {customer_ids: 1}]).limit(1).first
      assert app.id == @app3.id

      app = App.find_by_all_tags([{currency: 'USD'}, {customer_ids: 2}]).limit(1).first
      assert app.id == @app2.id

      app = App.find_by_all_tags([{currency: 'CAD'}, {customer_ids: 2}]).limit(1).first
      assert app.id == @app4.id
    end

  end