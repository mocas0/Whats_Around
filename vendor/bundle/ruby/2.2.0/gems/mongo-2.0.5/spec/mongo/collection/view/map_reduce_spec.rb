require 'spec_helper'

describe Mongo::Collection::View::MapReduce do

  let(:map) do
  %Q{
  function() {
    emit(this.name, { population: this.population });
  }}
  end

  let(:reduce) do
    %Q{
    function(key, values) {
      var result = { population: 0 };
      values.forEach(function(value) {
        result.population += value.population;
      });
      return result;
    }}
  end

  let(:documents) do
    [
      { name: 'Berlin', population: 3000000 },
      { name: 'London', population: 9000000 }
    ]
  end

  let(:selector) do
    {}
  end

  let(:view_options) do
    {}
  end

  let(:view) do
    Mongo::Collection::View.new(authorized_collection, selector, view_options)
  end

  let(:options) do
    {}
  end

  before do
    authorized_collection.insert_many(documents)
  end

  after do
    authorized_collection.find.delete_many
  end

  let(:map_reduce) do
    described_class.new(view, map, reduce, options)
  end

  describe '#each' do

    context 'when no options are provided' do

      it 'iterates over the documents in the result' do
        map_reduce.each do |document|
          expect(document[:value]).to_not be_nil
        end
      end
    end

    context 'when out is inline' do

      let(:new_map_reduce) do
        map_reduce.out(inline: 1)
      end

      it 'iterates over the documents in the result' do
        new_map_reduce.each do |document|
          expect(document[:value]).to_not be_nil
        end
      end
    end

    context 'when out is a collection' do

      after do
        authorized_client['output_collection'].find.delete_many
      end

      context 'when the option is to replace' do

        let(:new_map_reduce) do
          map_reduce.out(replace: 'output_collection')
        end

        it 'iterates over the documents in the result' do
          new_map_reduce.each do |document|
            expect(document[:value]).to_not be_nil
          end
        end

        it 'fetches the results from the collection' do
          expect(new_map_reduce.count).to eq(2)
        end
      end

      context 'when the option is to merge' do

        let(:new_map_reduce) do
          map_reduce.out(merge: 'output_collection')
        end

        it 'iterates over the documents in the result' do
          new_map_reduce.each do |document|
            expect(document[:value]).to_not be_nil
          end
        end

        it 'fetches the results from the collection' do
          expect(new_map_reduce.count).to eq(2)
        end
      end

      context 'when the option is to reduce' do

        let(:new_map_reduce) do
          map_reduce.out(reduce: 'output_collection')
        end

        it 'iterates over the documents in the result' do
          new_map_reduce.each do |document|
            expect(document[:value]).to_not be_nil
          end
        end

        it 'fetches the results from the collection' do
          expect(new_map_reduce.count).to eq(2)
        end
      end
    end

    context 'when the view has a selector' do

      context 'when the selector is basic' do

        let(:selector) do
          { name: 'Berlin' }
        end

        it 'applies the selector to the map/reduce' do
          map_reduce.each do |document|
            expect(document[:_id]).to eq('Berlin')
          end
        end

        it 'includes the selector in the operation spec' do
          expect(map_reduce.send(:map_reduce_spec)[:selector][:query]).to eq(selector)
        end
      end

      context 'when the selector is advanced' do

        let(:selector) do
          { :$query => { name: 'Berlin' }}
        end

        it 'applies the selector to the map/reduce' do
          map_reduce.each do |document|
            expect(document[:_id]).to eq('Berlin')
          end
        end

        it 'includes the selector in the operation spec' do
          expect(map_reduce.send(:map_reduce_spec)[:selector][:query]).to eq(selector[:$query])
        end
      end
    end

    context 'when the view has a limit' do

      let(:view_options) do
        { limit: 1 }
      end

      it 'applies the limit to the map/reduce' do
        map_reduce.each do |document|
          expect(document[:_id]).to eq('Berlin')
        end
      end
    end
  end

  describe '#finalize' do

    let(:finalize) do
    %Q{
    function(key, value) {
      value.testing = test;
      return value;
    }}
    end

    let(:new_map_reduce) do
      map_reduce.finalize(finalize)
    end

    it 'sets the finalize function' do
      expect(new_map_reduce.finalize).to eq(finalize)
    end

    it 'includes the finalize function in the operation spec' do
      expect(new_map_reduce.send(:map_reduce_spec)[:selector][:finalize]).to eq(finalize)
    end
  end

  describe '#js_mode' do

    let(:new_map_reduce) do
      map_reduce.js_mode(true)
    end

    it 'sets the js mode value' do
      expect(new_map_reduce.js_mode).to be true
    end

    it 'includes the js mode value in the operation spec' do
      expect(new_map_reduce.send(:map_reduce_spec)[:selector][:jsMode]).to be(true)
    end
  end

  describe '#out' do

    let(:location) do
      { replace: 'testing' }
    end

    let(:new_map_reduce) do
      map_reduce.out(location)
    end

    it 'sets the out value' do
      expect(new_map_reduce.out).to eq(location)
    end

    it 'includes the out value in the operation spec' do
      expect(new_map_reduce.send(:map_reduce_spec)[:selector][:out]).to be(location)
    end

    context 'when out is not defined' do

      it 'defaults to inline' do
        expect(map_reduce.send(:map_reduce_spec)[:selector][:out]).to eq(inline: 1)
      end
    end
  end

  describe '#scope' do

    let(:object) do
      { value: 'testing' }
    end

    let(:new_map_reduce) do
      map_reduce.scope(object)
    end

    it 'sets the scope object' do
      expect(new_map_reduce.scope).to eq(object)
    end

    it 'includes the scope object in the operation spec' do
      expect(new_map_reduce.send(:map_reduce_spec)[:selector][:scope]).to be(object)
    end
  end

  describe '#verbose' do

    let(:verbose) do
      false
    end

    let(:new_map_reduce) do
      map_reduce.verbose(verbose)
    end

    it 'sets the verbose value' do
      expect(new_map_reduce.verbose).to be(false)
    end

    it 'includes the verbose option in the operation spec' do
      expect(new_map_reduce.send(:map_reduce_spec)[:selector][:verbose]).to eq(verbose)
    end
  end

  context 'when limit is set on the view' do

    let(:limit) do
      3
    end

    let(:view_options) do
      { limit: limit }
    end

    it 'includes the limit in the operation spec' do
      expect(map_reduce.send(:map_reduce_spec)[:selector][:limit]).to be(limit)
    end
  end

  context 'when sort is set on the view' do

    let(:sort) do
      { name: -1 }
    end

    let(:view_options) do
      { sort: sort }
    end

    it 'includes the sort object in the operation spec' do
      expect(map_reduce.send(:map_reduce_spec)[:selector][:sort]).to be(sort)
    end
  end

  context 'when the collection has a read preference' do

    let(:read_preference) do
      Mongo::ServerSelector.get(mode: :secondary)
    end

    it 'includes the read preference in the spec' do
      allow(authorized_collection).to receive(:read_preference).and_return(read_preference)
      expect(map_reduce.send(:map_reduce_spec)[:read]).to eq(read_preference)
    end
  end
end
