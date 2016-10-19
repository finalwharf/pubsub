require_relative '../lib/broker'

include PubSub

# rubocop:disable BlockLength
describe Broker do
  before do
    @broker = Broker.new

    logger = double('Logger').as_null_object
    allow(@broker).to receive(:logger).and_return(logger)

    tcp_server = instance_double('TCPServer')
    allow(tcp_server).to receive(:closed?).and_return(false, true)
    allow(tcp_server).to receive(:addr).and_return([])

    allow(@broker).to receive(:create_server).and_return(tcp_server)
  end

  it 'is an instance of a broker class' do
    expect(described_class).to equal(Broker)
  end

  it 'binds to the specified address and port' do
    expect(@broker.bind).to be_truthy
    expect(@broker.socket).to_not be_nil
    expect(@broker.readable_sockets).to eq [@broker.socket]
  end

  it 'starts the server' do
    @broker.bind
    expect(@broker).to receive(:read_blocking).and_return([])
    @broker.start
  end

  it 'stops the server' do
    expect(@broker.socket).to receive(:close)
    @broker.stop
  end

  it 'reads from a client socket' do
    socket = instance_double('TCPSocket')
    allow(socket).to receive(:gets).and_return('{"a":"b"}')

    data = @broker.socket_read(socket)
    expect(data).to eq('a' => 'b')
  end

  it 'writes to a client socket' do
    socket = instance_double('TCPSocket')
    expect(socket).to receive(:puts).with('{"a":"b"}')

    @broker.socket_write(socket, 'a' => 'b')
  end

  it 'determines client type' do
    client = instance_double('TCPSocket')
    data = '{"client_type":"subscriber"}'

    allow(client).to receive(:gets).and_return(data)
    allow(@broker).to receive(:client_ready_for_read?).with(client)
                                                      .and_return(true)

    client_type = @broker.determine_client_type(client)
    expect(client_type).to eq('subscriber')
  end

  it 'handles publisher connections' do
    client = instance_double('TCPSocket')

    @broker.bind
    @broker.handle_publisher_connection(client)

    expect(@broker.readable_sockets).to eq [@broker.socket, client]
    expect(@broker.publishers).to eq [client]
  end

  it 'handles subscriber connections and subscriptions' do
    client = instance_double('TCPSocket')

    data = {
      'topics' => ['cars']
    }

    subscriptions = {
      'cars' => [client]
    }

    allow(@broker).to receive(:socket_read).with(client).and_return(data)

    @broker.handle_subscriber_connection(client)

    expect(@broker.topic_subscribers).to eq subscriptions
  end

  it 'handles client connections' do
    @broker.bind

    client = instance_double('TCPSocket')

    allow(@broker.socket).to receive(:accept).and_return(client)

    allow(@broker).to receive(:determine_client_type).and_return('publisher')
    expect(@broker).to receive(:handle_publisher_connection).with(client)
    @broker.handle_client_connection

    allow(@broker).to receive(:determine_client_type).and_return('subscriber')
    expect(@broker).to receive(:handle_subscriber_connection).with(client)
    @broker.handle_client_connection
  end

  it 'handles published messages' do
    client    = instance_double('TCPSocket')
    publisher = instance_double('TCPSocket')

    @broker.topic_subscribers = { 'cars' => [client] }

    data = { 'topic' => 'cars', 'message' => 'test message' }
    allow(@broker).to receive(:socket_read).with(publisher).and_return(data)

    expect(@broker).to receive(:socket_write).with(client, data)

    @broker.handle_published_message(publisher)
  end

  after do
    @broker = nil
  end
end
