# rate_limiter

A utility class for rate limiting, ported from @meew0's implementation in [discordrb](https://github.com/meew0/discordrb/blob/master/lib/discordrb/commands/rate_limiter.rb)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  rate_limiter:
    github: z64/rate_limiter
```

## Usage

```crystal
require "rate_limiter"

# Make a new rate limiter that will limit based on string "usernames"
limiter = RateLimiter(String).new

# Create a bucket that allows 3 requests per second
limiter.bucket(:foo, 3_u32, 1.seconds)

# Perform a request on "z64"
limiter.rate_limited?(:foo, "z64")
```

## Contributors

- [z64](https://github.com/z64) Zac Nowicki - creator, maintainer
