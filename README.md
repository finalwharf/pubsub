# PubSub

This is a simple PubSub implementation in Ruby.


## Usage:

Go go the `demo` folder

```
$ cd demo/
```


Start the broker on port 3001

```
$ ./broker.rb 3001
```

Start the subscriber on port 3001 and listen on topics cars and girls

```
$ ./subscriber.rb 3001 cars girls
```


Start the publisher on port 3001

```
$ ./publisher.rb 3001
```
