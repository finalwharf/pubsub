require_relative '../lib/subscriber'

include PubSub

# rubocop:disable BlockLength
describe Subscriber do
  before do
    @subscriber = Subscriber.new

    logger = double('Logger').as_null_object
    allow(@subscriber).to receive(:logger).and_return(logger)

    tcp_socket = instance_double('TCPSocket')
    allow(tcp_socket).to receive(:peeraddr).and_return([])

    allow(@subscriber).to receive(:create_socket).and_return(tcp_socket)
  end

  it 'connects to the broker on a specified address and port' do
    expect(@subscriber).to receive(:identify)
    expect(@subscriber.connect).to be true
    expect(@subscriber.socket).to_not be_nil
  end

  it 'checks if subscriber is connected' do
    allow(@subscriber.socket).to receive(:closed?).and_return(false)
    expect(@subscriber.connected?).to be true

    allow(@subscriber.socket).to receive(:closed?).and_return(true)
    expect(@subscriber.connected?).to be false
  end

  it 'disconnects from the broker' do
    expect(@subscriber.socket).to receive(:close)
    @subscriber.disconnect
  end

  it 'identifies to the broker' do
    expected_data = { client_type: 'subscriber' }
    expect(@subscriber).to receive(:socket_write).with(expected_data)

    @subscriber.identify
  end

  it 'receives a message message' do
    allow(@subscriber).to receive(:socket_read_blocking).and_return('{"a":"b"}')

    data = @subscriber.receive_message
    expect(data).to eq('a' => 'b')
  end

  it 'subscribes to a list of topics' do
    expect(@subscriber).to receive(:socket_write).with(topics: ['cars'])
    @subscriber.subscribe(['cars'])
  end

  it 'reads from socket' do
    @subscriber.socket = @subscriber.create_socket('0.0.0.0', 1234)
    allow(@subscriber.socket).to receive(:gets).and_return('{"a":"b"}')

    data = @subscriber.socket_read_blocking
    expect(data).to eq('{"a":"b"}')
  end

  it 'writes to socket' do
    @subscriber.socket = @subscriber.create_socket('0.0.0.0', 1234)
    expect(@subscriber.socket).to receive(:puts).with('{"a":"b"}')
    @subscriber.socket_write('a' => 'b')
  end

  after do
    @subscriber = nil
  end
end
