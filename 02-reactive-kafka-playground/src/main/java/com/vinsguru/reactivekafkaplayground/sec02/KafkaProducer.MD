## 1. Basic Setup

Kafka uses the `KafkaSender` class (from Reactor Kafka), which is a wrapper around the standard Kafka `Producer`.

### Step-by-Step:
1. Create Producer Config Map
```java
Map<String, Object> producerConfig = Map.of(
    ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092",
    ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class,
    ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class
);

```
2. Create Sender Options

```java
SenderOptions<String, String> senderOptions = SenderOptions.create(producerConfig);

```
3. Create KafkaSender
```java
KafkaSender<String, String> kafkaSender = KafkaSender.create(senderOptions);

```
4. Sending Messages
- To send messages, you need to send a Flux of SenderRecord<K, V, T>.
- Each SenderRecord holds:
- A ProducerRecord (with topic, key, value)
- An optional correlation metadata (T)
```java
Flux<SenderRecord<String, String, String>> outboundFlux = Flux.just("event1", "event2", "event3")
    .map(data -> {
        ProducerRecord<String, String> record = new ProducerRecord<>("your-topic-name", data);
        return SenderRecord.create(record, data); // 'data' used as correlation metadata
    });

kafkaSender.send(outboundFlux)
    .doOnError(e -> System.err.println("Send failed: " + e))
    .doOnNext(result -> {
        RecordMetadata metadata = result.recordMetadata();
        System.out.printf("Message sent to topic %s, partition %d, offset %d%n",
                          metadata.topic(), metadata.partition(), metadata.offset());
    })
    .subscribe();

```

## Handling Sender Record Types

Kafka’s `KafkaSender.send()` expects a `Flux<SenderRecord<K, V, CorrelationMetadata>>`.

So, for example:

- `K = String` (Key)
- `V = String` (Value)
- `CorrelationMetadata = String` (for tracking message delivery)

To make sure we have proper type inference, explicitly define types:

```java
KafkaSender<String, String> sender = KafkaSender.create(senderOptions);
// Later when creating Flux<SenderRecord<String, String, String>>
```

### Creating a Flux of Sender Records
- To simulate sending 100 messages every 100 milliseconds:

```java
Flux<SenderRecord<String, String, String>> outboundFlux = Flux
    .interval(Duration.ofMillis(100))
    .take(100)
    .map(i -> {
        String key = String.valueOf(i);
        String value = "order-" + i;
        ProducerRecord<String, String> producerRecord = new ProducerRecord<>("order-events", key, value);
        return SenderRecord.create(producerRecord, key); // Correlation metadata = key
    });

```
#### Notes:
- ProducerRecord is from Apache Kafka. 
- SenderRecord is from Reactor Kafka, wrapping the ProducerRecord and adding metadata.
- Correlation metadata helps track message delivery success on a per-record basis.

### Sending Records to Kafka
- Use the sender to send the flux:
```java
sender.send(outboundFlux)
    .doOnNext(result -> {
        String correlationId = result.correlationMetadata();
        log.info("✅ Correlation ID: {}", correlationId);
    })
    .doOnError(error -> log.error("❌ Failed to send record", error))
    .subscribe();

```
- This setup allows you to:
- Continuously stream records into Kafka.
- Log and verify successful delivery for each record using the correlation ID.
- Handle and log errors gracefully.

### Summary
- Use Flux.interval() for periodic event generation.
- Use SenderRecord to wrap ProducerRecord with correlation metadata.
- Kafka will deliver messages asynchronously and return metadata that can be used for tracking.
- Logging correlation IDs helps verify successful deliveries.