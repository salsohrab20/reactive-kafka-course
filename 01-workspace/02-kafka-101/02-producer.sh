# to produce messages
kafka-console-producer.sh --bootstrap-server localhost:9092 --topic hello-world

# linger.ms (1000ms - 1 sec) - for reducing the lag in transfering the message from producer to consumer
kafka-console-producer.sh --bootstrap-server localhost:9092 --topic hello-world --timeout 100

# batch.size(bytes) - 1 more property in producer side that we can configure- it basically implies to pass events after we have already passed events worth this much batch.size