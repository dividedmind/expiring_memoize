require "expiring_memoize/version"

module ExpiringMemoize
  # Memoize a nullary method.
  # @param name [Symbol] method to memoize
  # @option ttl [Number] time to live of the value, in seconds
  def memoize name, ttl: Float::INFINITY
    original = instance_method name
    raise ArgumentError, 'only nullary methods supported' unless original.arity.zero?

    define_method name do
      data = ((@_expiring_memoize_data ||= {})[name] ||= {})
      loop do
        # no need to synchronize here -- worst case,
        # we return a value fresher than expected.
        # (plus, global interpreter lock in MRI makes it safe regardless)
        unless (ts = data[:timestamp]) && (ExpiringMemoize.gettime - ts) < ttl
          # value is stale, race to fetch
          mutex ||= (data[:mutex] ||= Mutex.new)
          if mutex.try_lock
            # our thread won the race, let's get the value
            begin
              data[:value] = original.bind(self).call
              data[:timestamp] = ExpiringMemoize.gettime
            ensure
              mutex.unlock
            end
          else
            # our thread lost, block on the mutex and try again
            mutex.synchronize {}
            next
          end
        end
        return data[:value]
      end
    end
  end

  # @nodoc
  def self.gettime
    Process.clock_gettime Process::CLOCK_MONOTONIC_COARSE
  end
end
