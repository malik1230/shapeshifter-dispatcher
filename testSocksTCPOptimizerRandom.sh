# This script runs a full end-to-end functional test of the dispatcher and the Replicant transportOptimizer transport with the Random Strategy. Each netcat instance can be used to type content which should appear in the other.
FILENAME=testSocksTCPOptimizerRandomOutput.txt
# Update and build code
go get -u github.com/OperatorFoundation/shapeshifter-dispatcher

# remove text from the output file
rm $FILENAME

# Run a demo application server with netcat and write to the output file
nc -l 3333 >$FILENAME &

# Run the transport server
export TOR_PT_SERVER_BINDADDR=shadow-127.0.0.1:2222
./shapeshifter-dispatcher -server -state state -orport 127.0.0.1:3333 -transports shadow -optionsFile shadowServer.json -logLevel DEBUG -enableLogging &
export TOR_PT_SERVER_BINDADDR=obfs2-127.0.0.1:2222
./shapeshifter-dispatcher -server -state state -orport 127.0.0.1:3333 -transports obfs2 -logLevel DEBUG -enableLogging &
export TOR_PT_SERVER_BINDADDR=Replicant-127.0.0.1:2222
./shapeshifter-dispatcher -server -state state -orport 127.0.0.1:3333 -transports Replicant -optionsFile ReplicantServerConfig1.json -logLevel DEBUG -enableLogging &

sleep 5

# Run the transport client
export TOR_PT_ORPORT=127.0.0.1:2222
./shapeshifter-dispatcher -client -state state -transports Optimizer -proxylistenaddr 127.0.0.1:1443 -optionsFile OptimizerRandom.json -logLevel DEBUG -enableLogging &

sleep 1

# Run a demo application client with netcat
go test -run SocksTCPOptimizerRandom

sleep 1

OS=$(uname)

if [ "$OS" = "Darwin" ]
then
  FILESIZE=$(stat -f%z "$FILENAME")
else
  FILESIZE=$(stat -c%s "$FILENAME")
fi

if [ "$FILESIZE" = "0" ]
then
  echo "Test Failed"
  killall shapeshifter-dispatcher
  killall nc
  exit 1
fi

echo "Testing complete. Killing processes."

killall shapeshifter-dispatcher
killall nc

echo "Done."
