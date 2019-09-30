RSpec.describe ExpiringMemoize do
  subject :counter do
    Class.new do
      def initialize count = 0
        @count = count
      end

      def count
        (@count += 1).tap do |val|
          fail "bad value" if (val % 10).zero?
        end
      end

      extend ExpiringMemoize
      memoize :count, ttl: 1
    end
  end

  it "is thread-safe" do
    # Run a couple threads for a second, each probing the the counter more
    # often than ttl. After the second elapses, each thread should have seen
    # only values 1..9.
    obj = counter.new
    expect(obj.count).to eq 1
    results = 5.times.map { [] }

    threads = 5.times.map do |idx|
      Thread.new do
        loop do
          results[idx] << obj.count
          sleep 0.001
        end
      end
    end

    9.times { sleep 0.01; tick }
    threads.each &:exit
    expect(results.map(&:uniq)).to eq [(1..9).to_a] * 5
  end

  it "is exception-safe" do
    obj = counter.new 9
    expect { obj.count }.to raise_error 'bad value'
    expect(obj.count).to eq 11
    expect(obj.count).to eq 11
    tick
    expect(obj.count).to eq 12
  end

  # We're not using real clock for testing because in a busy machine we can get
  # preempted and count more than we want. Also faking makes the test faster.
  def clock
    @clock ||= 0.0
    @clock += 0.00001
  end

  def tick interval = 1
    @clock += interval
  end

  before do
    allow(ExpiringMemoize).to receive(:gettime) { clock }
  end
end
