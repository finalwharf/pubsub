require_relative '../lib/publisher'

include PubSub

# rubocop:disable BlockLength
describe Publisher do
  before do
    @publisher = Publisher.new

    logger = double('Logger').as_null_object
    allow(@publisher).to receive(:logger).and_return(logger)

    tcp_socket = instance_double('TCPSocket')
    allow(tcp_socket).to receive(:peeraddr).and_return([])

    allow(@publisher).to receive(:create_socket).and_return(tcp_socket)
  end

  it 'connects to the broker on a specified address and port' do
    expect(@publisher).to receive(:identify)
    expect(@publisher.connect).to be true
    expect(@publisher.socket).to_not be_nil
  end

  it 'checks if publisher is connected' do
    allow(@publisher.socket).to receive(:closed?).and_return(false)
    expect(@publisher.connected?).to be true

    allow(@publisher.socket).to receive(:closed?).and_return(true)
    expect(@publisher.connected?).to be false
  end

  it 'disconnects from the broker' do
    expect(@publisher.socket).to receive(:close)
    @publisher.disconnect
  end

  it 'identifies to the broker' do
    expected_data = { client_type: 'publisher' }
    expect(@publisher).to receive(:socket_write).with(expected_data)

    @publisher.identify
  end

  it 'publishes a message to the broker' do
    expect(@publisher).to receive(:socket_write).with(
      topic: 'cars',
      message: 'test message'
    )
    @publisher.publish('cars', 'test message')
  end

  it 'writes to the socket' do
    @publisher.socket = @publisher.create_socket('0.0.0.0', 1234)
    expect(@publisher.socket).to receive(:puts).with('{"a":"b"}')
    @publisher.socket_write('a' => 'b')
  end

  after do
    @publisher = nil
  end
end
