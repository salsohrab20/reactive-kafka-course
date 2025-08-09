### 🧩 Key Classes in Reactor Kafka

| Class             | Purpose                                            |
| ----------------- | -------------------------------------------------- |
| `KafkaReceiver`   | Core class to consume messages reactively.         |
| `KafkaSender`     | Core class to produce messages reactively.         |
| `ReceiverOptions` | Holds configuration for the consumer.              |
| `SenderOptions`   | Holds configuration for the producer (used later). |

These are wrappers around Apache Kafka’s own **KafkaConsumer** and **KafkaProducer**.

### ✅ Creating a Reactive Kafka Consumer
- Create Configuration Map
   ```java
  Map<String, Object> consumerConfig = Map.of(
   ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092",
   ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class,
   ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class,
   ConsumerConfig.GROUP_ID_CONFIG, "demo-group"
   );
   ``` 
  
- Kafka needs to know how to deserialize keys and values (byte[] → String, for example).
- Every consumer must belong to a consumer group.

- Create Receiver Options
   ```java
   ReceiverOptions<String, String> receiverOptions = ReceiverOptions.create(consumerConfig);
  ```
   You can also provide topic subscriptions and other options on top of this.

- Create Kafka Receiver
   ```java
   KafkaReceiver<String, String> kafkaReceiver = KafkaReceiver.create(receiverOptions);
  ```
   This sets up the reactive consumer, ready to subscribe to events.

### 💬 Notes on Consumer Configuration
- Kafka configuration is modular:
- Consumers, producers, and brokers each have separate config sets.

Example: log.retention.hours is for the broker, not the consumer.

- Refer to official Kafka configuration docs for default values and detailed explanations.

📚 Console Consumer Equivalent
This setup mimics what you do via:

```bash
kafka-console-consumer.sh \
--bootstrap-server localhost:9092 \
--topic my-topic \
--from-beginning \
--group-id demo-group
```
Now you're replicating that logic using Reactor Kafka programmatically.