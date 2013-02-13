require 'spec_helper'

describe Warden::GitHub::MembershipCache do
  subject(:cache) do
    described_class.new
  end

  describe '#fetch_membership' do
    it 'returns false by default' do
      cache.fetch_membership('foo', 'bar').should be_false
    end

    context 'when cache valid' do
      before do
        cache['foo'] = {}
        cache['foo']['bar'] = Time.now.to_i - described_class::CACHE_TIMEOUT + 5
      end

      it 'returns true' do
        cache.fetch_membership('foo', 'bar').should be_true
      end

      it 'does not invoke the block' do
        expect { |b| cache.fetch_membership('foo', 'bar', &b) }.
          to_not yield_control
      end
    end

    context 'when cache expired' do
      before do
        cache['foo'] = {}
        cache['foo']['bar'] = Time.now.to_i - described_class::CACHE_TIMEOUT - 5
      end

      context 'when no block given' do
        it 'returns false' do
          cache.fetch_membership('foo', 'bar').should be_false
        end
      end

      it 'deletes the cached value' do
        cache.fetch_membership('foo', 'bar')
        cache['foo'].should_not have_key('bar')
      end

      it 'invokes the block' do
        expect { |b| cache.fetch_membership('foo', 'bar', &b) }.
          to yield_control
      end
    end

    it 'caches the value when block returns true' do
      cache.fetch_membership('foo', 'bar') { true }
      cache.fetch_membership('foo', 'bar').should be_true
    end

    it 'does not cache the value when block returns false' do
      cache.fetch_membership('foo', 'bar') { false }
      cache.fetch_membership('foo', 'bar').should be_false
    end
  end
end
