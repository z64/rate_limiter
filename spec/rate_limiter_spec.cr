require "./spec_helper"

describe RateLimiter do
  describe RateLimiter::Bucket do
    it "returns false on a new bucket" do
      bucket = RateLimiter::Bucket(Int32).new(0_u32, 0.seconds, 0.seconds)
      bucket.rate_limited?(0).should be_false
    end

    it "returns the remaining time when count is over the limit and time hasn't run out" do
      bucket = RateLimiter::Bucket(Int32).new(1_u32, 1.seconds, 5.seconds)
      bucket.rate_limited?(0)
      bucket.rate_limited?(0).should be_a(Time::Span)
    end

    it "returns false on no rate limiting" do
      bucket = RateLimiter::Bucket(Int32).new(2_u32, 1.seconds, 0.seconds)
      bucket.rate_limited?(0)
      bucket.rate_limited?(0).should be_false
    end

    it "returns the remaining time when being delayed" do
      bucket = RateLimiter::Bucket(Int32).new(1_u32, 1.seconds, 5.seconds)
      bucket.rate_limited?(0)
      bucket.rate_limited?(0, Time.utc + 1.seconds).should be_a(Time::Span)
    end

    it "cleans unused buckets" do
      bucket = RateLimiter::Bucket(Int32).new(1_u32, 1.seconds, 1.seconds)
      bucket.rate_limited?(0)
      bucket.clean(Time.utc + 1.seconds)
      bucket.rate_limited?(0).should be_false
    end
  end

  it "creates a new bucket" do
    limiter = RateLimiter(Int32).new
    limiter.bucket(:foo, 1_u32, 0.seconds, 0.seconds).should be_a(RateLimiter::Bucket(Int32))
  end

  it "handles rate limits" do
    limiter = RateLimiter(Int32).new
    limiter.bucket(:foo, 1_u32, 0.seconds, 0.seconds)

    limiter.rate_limited?(:foo, 0).should be_false
  end
end
