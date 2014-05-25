require 'json'

module RCL
  extend ActiveSupport::Concern


  module ClassMethods
    def rall
      key = "#{cls_name}:indices:all"
      create_indices(key, -> { all })

      ids = $redis.smembers(key)
      get_cached_records(ids)
    end

    def rwhere(conditions = {})
      raise "No conditions" if conditions.size == 0

      keys = conditions.map do |k, v|
        key = "#{cls_name}:indices:#{k}:#{v}"
        create_indices(key, -> { where(k => v) })
        key
      end


      ids = if keys.size > 1
        $redis.sinter(keys)
      else
        $redis.smembers(keys.first)
      end

      get_cached_records(ids)

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

    # def get_collection(ids, condition)
    #   if $redis.exists(collection_key)
    #     ids = $redis.smembers(collection_key)
    #     result = get_cached_records(ids)
    #   else
    #     result = create_indices(collection_key, condition)
    #   end
    #
    #   result
    # end

    def create_indices(key, condition)
      unless $redis.exists(key)
        logger.debug "Creating indices for #{key}"
        result = condition.call
        if result.count > 0
          $redis.pipelined do
            $redis.sadd(key, result.map(&:id))
            set_expiration_time(key)
          end
        end
        cache_result(result)
      end

    end

    def get_cached_records(ids)
      $redis.pipelined do
        ids.each do |id|
          logger.debug "Getting cached result for #{cls_name}:#{id}"
          $redis.hgetall("#{cls_name}:#{id}")
        end
      end
    end

    def cache_result(result)
      $redis.pipelined do
        result.each do |r|
          record_key = "#{cls_name}:#{r.id}"
          logger.debug "Cache result for #{record_key}"

          $redis.hmset(record_key, r.attributes.to_a.flatten)
          set_expiration_time(record_key)
        end
      end
    end

    def set_expiration_time(key)
      logger.debug "Setting expiration time for #{key}"
      $redis.expireat(key, 10.minute.from_now.to_time.to_i)
    end


    def cls_name
      to_s
    end
  end

end
