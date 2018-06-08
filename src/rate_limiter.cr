# A utility class for performing rate limit queries under certain
# conditions. See `specs/` for example usage.
class RateLimiter(T)
  VERSION = "0.1.0"

  # A `Bucket` collects rate limit queries and handle rate limiting logic
  class Bucket(K)
    # A `Query` represents an accumulative record of rate limit requests
    class Query
      # The last time this query was hit
      property last_time : Time

      # When this queries count was initialized (set to 0)
      property set_time : Time

      # The number of times this query has been hit
      property count : UInt32

      def initialize(@last_time : Time, @set_time : Time, @count : UInt32)
      end
    end

    # Creates a new bucket that enforces a `limit` within a `time_span`,
    # optionally enforcing a minimum `delay` between queries.
    def initialize(@limit : UInt32, @time_span : Time::Span,
                   @delay : Time::Span = 0.seconds)
      @bucket = {} of K => Query
    end

    # Performs a rate limit request on a certain `key`
    def rate_limited?(key : K, rate_limit_time = nil)
      query = @bucket[key]?

      # 1. Query doesn't exist yet; insert a default query and return `false`
      unless query
        @bucket[key] = Query.new(Time.now, Time.now, 1_u32)
        return false
      end

      # Define the time at which we're being rate limited once so it doesn't
      # get inaccurate
      rate_limit_time ||= Time.now

      if @limit && (query.count + 1) > @limit
        # 2. Count is over the limit, and the time hasn't run out yet
        return (query.set_time + @time_span) - rate_limit_time if @time_span && rate_limit_time < (query.set_time + @time_span)

        # 3. Count is over the limit, but the time has run out
        # Don't return anything here because there may still be delay-based limiting
        query.set_time = rate_limit_time
        query.count = 0_u32
      end

      if @delay && rate_limit_time < (query.last_time + @delay)
        # 4. We're being delayed
        (query.last_time + @delay) - rate_limit_time
      else
        # 5. No rate limiting. Increment the count, set the `last_time`, and return `false`
        query.last_time = rate_limit_time
        query.count += 1
        false
      end
    end

    # Cleans the bucket, removing all elements that aren't necessary anymore.
    # Accepts a `Time` to base the cleaning on, only useful for testing.
    def clean(rate_limit_time = nil)
      rate_limit_time ||= Time.now

      @bucket.delete_if do |_, query|
        return false if @time_span && rate_limit_time < (query.set_time + @time_span)

        return false if @delay && rate_limit_time < (query.set_time + @time_span)

        true
      end
    end
  end

  def initialize
    @buckets = {} of Symbol => Bucket(T)
  end

  # Creates a new bucket with `name` and specified properties.
  # See `Bucket#initialize`
  def bucket(name : Symbol, limit : UInt32, time_span : Time::Span, delay : Time::Span = 0.seconds)
    @buckets[name] = Bucket(T).new(limit, time_span, delay)
  end

  # Cleans all buckets.
  # See `Bucket#clean`.
  def clean
    @buckets.each &.clean
  end

  # Searches for a bucket with `name`, and performs a rate limit request
  # with `key`
  def rate_limited?(name : Symbol, key : T)
    if bucket = @buckets[name]?
      bucket.rate_limited?(key)
    else
      false
    end
  end
end
