# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::BulkInsertSupport do
  class ItemDependency < ApplicationRecord
    belongs_to :bulk_insert_item
  end

  class BulkInsertItem < ApplicationRecord
    attr_reader :after, :before_save_count, :after_save_count
    attr_writer :fail_before_save
    attr_writer :fail_after_save

    after_initialize do
      @before_save_count = 0
      @after_save_count = 0
    end

    has_one :item_dependency

    before_save -> {
      @before_save_count += 1

      raise "failed in before_save" if @fail_before_save

      self.before = "#{name} set from before_save"
    }

    after_save -> {
      @after_save_count += 1

      raise "failed in after_save" if @fail_after_save

      @after = "#{name} set from after_save"
    }
  end

  before(:all) do
    ActiveRecord::Schema.define do
      create_table :bulk_insert_items, force: true do |t|
        t.string :name, null: false
        t.string :before, null: true
      end

      create_table :item_dependencies, force: true do |t|
        t.string :name
        t.belongs_to :bulk_insert_item, null: true
      end
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :item_dependencies, force: true
      drop_table :bulk_insert_items, force: true
    end
  end

  describe 'save_all!' do
    let(:good_item) { new_item }
    let(:bad_item) { new_item(name: nil) }

    it 'inserts all items from list' do
      items = Array.new(2) { new_item }

      expect do
        BulkInsertItem.save_all!(items)
      end.to change { BulkInsertItem.count }.from(0).to(2)

      BulkInsertItem.all do |item|
        expect(item.id).not_to be_nil
        expect(item.name).to eq("item")
      end
    end

    it 'inserts all items from varargs' do
      expect do
        BulkInsertItem.save_all!(new_item(name: "one"), new_item(name: "two"))
      end.to change { BulkInsertItem.count }.from(0).to(2)

      inserted = BulkInsertItem.all
      expect(inserted.size).to eq(2)
      expect(inserted.first.id).not_to be_nil
      expect(inserted.first.name).to eq('one')
      expect(inserted.last.id).not_to be_nil
      expect(inserted.last.name).to eq('two')
    end

    context 'before_save action' do
      it 'runs once before INSERT' do
        item1 = new_item(name: "one")
        item2 = new_item(name: "two")

        BulkInsertItem.save_all!(item1, item2)

        expect(item1.before_save_count).to eq(1)
        expect(item2.before_save_count).to eq(1)

        expect(item1.before).to eq("one set from before_save")
        expect(item2.before).to eq("two set from before_save")

        # these changes must survive a reload from DB, or they wouldn't have been persisted
        expect(item1.reload.before).to eq("one set from before_save")
        expect(item2.reload.before).to eq("two set from before_save")
      end

      it 'rolls back INSERT when failed' do
        item1 = new_item(name: "one")
        item2 = new_item(name: "two")
        item2.fail_before_save = true

        expect do
          BulkInsertItem.save_all!(item1, item2)
        rescue
        end.not_to change { BulkInsertItem.count }
      end
    end

    context 'after_save action' do
      it 'runs once after INSERT' do
        item1 = new_item(name: "one")
        item2 = new_item(name: "two")

        BulkInsertItem.save_all!(item1, item2)

        expect(item1.after_save_count).to eq(1)
        expect(item2.after_save_count).to eq(1)

        expect(item1.after).to eq("one set from after_save")
        expect(item2.after).to eq("two set from after_save")
      end

      it 'rolls back INSERT when failed' do
        item1 = new_item(name: "one")
        item2 = new_item(name: "two")
        item2.fail_after_save = true

        expect do
          BulkInsertItem.save_all!(item1, item2)
        rescue
        end.not_to change { BulkInsertItem.count }
      end
    end

    it 'throws when some or all items are not of the specified type' do
      expect { BulkInsertItem.save_all!(good_item, "not a `BulkInsertItem`") }.to(
        raise_error(Gitlab::Database::BulkInsertSupport::TargetTypeError)
      )
    end

    context 'when calls are nested' do
      class WithIllegalNestedCall < BulkInsertItem
        after_save -> { WithIllegalNestedCall.save_all!(self) }
      end

      class WithLegalNestedCall < BulkInsertItem
        after_save -> { ItemDependency.save_all!(ItemDependency.new(name: 'ok')) }
      end

      it 'throws when called on the same class' do
        expect { WithIllegalNestedCall.save_all!(WithIllegalNestedCall.new(name: 'not ok')) }.to(
          raise_error(Gitlab::Database::BulkInsertSupport::NestedCallError)
        )
      end

      it 'allows calls for other types' do
        expect { WithLegalNestedCall.save_all!(WithLegalNestedCall.new(name: 'ok')) }.to(
          change { ItemDependency.count }.from(0).to(1)
        )
      end
    end

    context 'when failures are present' do
      it 'propagates failures' do
        expect { BulkInsertItem.save_all!(bad_item) }.to raise_error(ActiveRecord::NotNullViolation)
      end

      it 'rolls back all changes' do
        expect do
          BulkInsertItem.save_all!(good_item, bad_item)
        rescue
        end.not_to change { BulkInsertItem.count }
      end
    end
  end

  private

  def new_item(name: 'item', dep: nil)
    BulkInsertItem.new(name: name, item_dependency: dep)
  end
end
