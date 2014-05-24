require 'json'

module RCL
  extend ActiveSupport::Concern


  module ClassMethods
    def rall
      ids_key = "#{cls_name}:indices:all"
      get_collection(ids_key, -> { all })
    end

    def rwhere(conditions = {})
      raise "No conditions" if conditions.size == 0

      attr_name = conditions.keys.first
      attr_value = conditions.values.first

      ids_key = "#{cls_name}:indices:#{attr_name}:#{attr_value}"
      result = get_collection(ids_key, -> { where(attr_name => attr_value ) })


      conditions.shift
      if conditions.size > 0
        result = where(id: result.map { |r| r["id"] }).where(conditions)
      end

      result
    end

    def rtop(attr_name, n)
      ids_key = "#{cls_name}:top:#{attr_name}"

      if $redis.exists(ids_key)
        ids = $redis.zrevrange(ids_key, 0, n)
        result = get_cached_records(ids)
      else
        result = order(attr_name => :desc).limit(n)
        $redis.pipelined do
          $redis.zadd(ids_key, result.map { |r| [r[attr_name], r["id"]] })
          set_expiration_time(ids_key)
        end
        cache_result(result)
      end

      result
    end

    def get_collection(collection_key, condition)
      if $redis.exists(collection_key)
        ids = $redis.smembers(collection_key)
        result = get_cached_records(ids)
      else
        result = condition.call
        if result.count > 0
          $redis.pipelined do
            $redis.sadd(collection_key, result.map(&:id))
            set_expiration_time(collection_key)
          end
        end
        cache_result(result)
      end

      result
    end

    def get_cached_records(ids)
      $redis.pipelined do
        ids.each do |id|
          $redis.hgetall("#{cls_name}:#{id}")
          logger.debug "Getting cached result for #{cls_name}:#{id}"
        end
      end
    end

    def cache_result(result)
      $redis.pipelined do
        result.each do |r|
          record_key = "#{cls_name}:#{r.id}"
          $redis.hmset(record_key, r.attributes.to_a.flatten)
          set_expiration_time(record_key)

          logger.debug "Cache result for #{record_key}"
        end
      end
    end

    def set_expiration_time(key)
      $redis.expireat(key, 1.minute.from_now.to_time.to_i)
      logger.debug "Setting expiration time for #{key}"
    end


    def cls_name
      to_s
    end
  end

end
