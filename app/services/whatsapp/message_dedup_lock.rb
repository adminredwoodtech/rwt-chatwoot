# Atomic dedup lock for WhatsApp incoming messages.
#
# Meta can deliver the same webhook event multiple times. This lock uses
# Redis SET NX EX to ensure only one worker processes a given source_id.
class Whatsapp::MessageDedupLock
  KEY_PREFIX = Redis::RedisKeys::MESSAGE_SOURCE_KEY
  DEFAULT_TTL = 1.day.to_i

  def initialize(source_id, ttl: DEFAULT_TTL)
    @key = format(KEY_PREFIX, id: source_id)
    @ttl = ttl
    @owner = SecureRandom.hex(16)
  end

  # Returns true when the lock is acquired (caller should proceed).
  # Returns false when another worker already holds the lock.
  def acquire!
    ::Redis::Alfred.set(@key, @owner, nx: true, ex: @ttl)
  end

  def release!
    # An expired/reacquired lock must never be deleted by the old worker.
    ::Redis::Alfred.delete_if_value(@key, @owner)
  end
end
