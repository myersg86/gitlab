# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::BulkInsertSupport do
  class ItemDependency < ApplicationRecord
    belongs_to :bulk_insert_item
  end

  class BulkInsertItem < ApplicationRecord
    attr_reader :after, :callback_invocations
    attr_writer :fail_before_save, :fail_after_save, :fail_after_commit

    after_initialize do
      @callback_invocations = {
        before_save: 0,
        before_create: 0,
        after_create: 0,
        after_save: 0,
        after_commit: 0,
        sequence: []
      }
    end

    has_one :item_dependency

    after_commit do
      @callback_invocations[:after_commit] += 1
      @callback_invocations[:sequence] << :after_commit

      raise "'id' must be set in after_commit" unless self.id
    end

    before_create do
      @callback_invocations[:before_create] += 1
      @callback_invocations[:sequence] << :before_create
    end

    before_save do
      @callback_invocations[:before_save] += 1
      @callback_invocations[:sequence] << :before_save

      raise "failed in before_save" if @fail_before_save

      # create something within the outer transaction so
      # we can test rollbacks
      ItemDependency.create!(name: 'before_save')

      self.before = "#{name} set from before_save"
    end

    after_save do
      @callback_invocations[:after_save] += 1
      @callback_invocations[:sequence] << :after_save
      raise "'id' must be set in after_save" unless self.id

      raise "failed in after_save" if @fail_after_save

      @after = "#{name} set from after_save"
    end

    after_create do
      @callback_invocations[:after_create] += 1
      @callback_invocations[:sequence] << :after_create
      raise "'id' must be set in after_create" unless self.id

      raise "failed in after_commit" if @fail_after_commit
    end
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

    it 'maintains correct AR callback order' do
      items = [new_item(name: "one"), new_item(name: "two")]

      BulkInsertItem.save_all!(items)

      expect(items.map { |i| i.callback_invocations[:sequence] }).to all(eq([
        :before_save,
        :before_create,
        :after_create,
        :after_save,
        :after_commit
      ]))
    end

    context 'before_save action' do
      it 'runs once for each item before INSERT' do
        item1 = new_item(name: "one")
        item2 = new_item(name: "two")

        BulkInsertItem.save_all!(item1, item2)

        expect(item1.callback_invocations[:before_save]).to eq(1)
        expect(item2.callback_invocations[:before_save]).to eq(1)

        expect(item1.before).to eq("one set from before_save")
        expect(item2.before).to eq("two set from before_save")

        # these changes must survive a reload from DB, or they wouldn't have been persisted
        expect(item1.reload.before).to eq("one set from before_save")
        expect(item2.reload.before).to eq("two set from before_save")
      end

      it 'rolls back changes when failed' do
        item1 = new_item(name: "one")
        item2 = new_item(name: "two")
        item2.fail_before_save = true

        expect do
          BulkInsertItem.save_all!(item1, item2)
        rescue
        end.not_to change { ItemDependency.count }
      end
    end

    context 'before_create action' do
      it 'runs once for each item before INSERT' do
        items = [new_item(name: "one"), new_item(name: "two")]

        BulkInsertItem.save_all!(items)

        expect(items.map { |i| i.callback_invocations[:before_create] }).to all(eq(1))
      end
    end

    context 'after_save action' do
      it 'runs once for each item after INSERT' do
        item1 = new_item(name: "one")
        item2 = new_item(name: "two")

        BulkInsertItem.save_all!(item1, item2)

        expect(item1.callback_invocations[:after_save]).to eq(1)
        expect(item2.callback_invocations[:after_save]).to eq(1)

        expect(item1.after).to eq("one set from after_save")
        expect(item2.after).to eq("two set from after_save")
      end

      it 'rolls back changes when failed' do
        item1 = new_item(name: "one")
        item2 = new_item(name: "two")
        item2.fail_after_save = true

        expect do
          BulkInsertItem.save_all!(item1, item2)
        rescue
        end.not_to change { BulkInsertItem.count }
        expect(ItemDependency.count).to eq(0)
      end
    end

    context 'after_create action' do
      it 'runs once for each item before INSERT' do
        items = [new_item(name: "one"), new_item(name: "two")]

        BulkInsertItem.save_all!(items)

        expect(items.map { |i| i.callback_invocations[:after_create] }).to all(eq(1))
      end

      it 'rolls back changes when failed' do
        item1 = new_item(name: "one")
        item2 = new_item(name: "two")
        item2.fail_after_commit = true

        expect do
          BulkInsertItem.save_all!(item1, item2)
        rescue
        end.not_to change { BulkInsertItem.count }
        expect(ItemDependency.count).to eq(0)
      end
    end

    context 'with concurrency' do
      let(:num_threads) { 10 }

      it 'works when called from multiple threads for same class' do
        threads = Array.new(num_threads) do
          Thread.new { new_item.tap { |i| BulkInsertItem.save_all!(i) } }
        end

        saved_items = threads.map(&:value)

        expect(BulkInsertItem.count).to eq(num_threads)
        expect(saved_items.map { |i| i.callback_invocations[:sequence] }).to all(eq([
          :before_save,
          :before_create,
          :after_create,
          :after_save,
          :after_commit
        ]))
      end

      it 'works when called from multiple threads for different classes' do
        threads = [
          Thread.new { BulkInsertItem.save_all!(new_item) },
          Thread.new { ItemDependency.save_all!(new_item_dep) },
          Thread.new { BulkInsertItem.save_all!(new_item) },
          Thread.new { ItemDependency.save_all!(new_item_dep) }
        ]

        threads.each(&:join)

        expect(BulkInsertItem.count).to eq(2)
        expect(ItemDependency.count).to eq(2 + 2) # also created from before_save
      end
    end

    context 'with batch size' do
      it 'performs bulk insert for each batch' do
        allow(Gitlab::Database).to receive(:bulk_insert).and_call_original
        items = Array.new(5) { |n| new_item(name: "item#{n}") }
        item_values = items.map do |i|
          { "before": "#{i.name} set from before_save", "name": i.name }.stringify_keys
        end

        BulkInsertItem.save_all!(items, batch_size: 2)

        # should produce 3 INSERTs: [one, two], [three, four], [five]
        expect(Gitlab::Database).to have_received(:bulk_insert)
          .with('bulk_insert_items', item_values[0..1], return_ids: true)
        expect(Gitlab::Database).to have_received(:bulk_insert)
          .with('bulk_insert_items', item_values[2..3], return_ids: true)
        expect(Gitlab::Database).to have_received(:bulk_insert)
          .with('bulk_insert_items', item_values[4..-1], return_ids: true)
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
          change { ItemDependency.count }.from(0).to(2) # count the extra insertion from before_save
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

  def new_item_dep(name: 'item_dep')
    ItemDependency.new(name: name)
  end
end
