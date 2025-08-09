## 📝 Kafka Console Producer & Consumer: Side-by-Side Demo

This section demonstrates how Kafka’s **console producer** and **console consumer** work together, and explains the behavior observed during real-time message streaming.

---

### 🔄 Running Consumer and Producer Side-by-Side

1. **Start the Console Consumer**:
   ```bash
   kafka-console-consumer.sh --bootstrap-server <broker>:9092 --topic <topic-name>
⚠️ If --from-beginning is not used, the consumer will wait for new messages only.

Start the Console Producer:

`kafka-console-producer.sh --bootstrap-server <broker>:9092 --topic <topic-name>`

Send Messages:
Type messages into the producer terminal and hit Enter.
Messages will appear in the consumer terminal in near real-time.

### ⏱️ Understanding the Lag (Producer Batching)
You may notice a slight delay before messages show up on the consumer side. This is expected and is due to the default batching behavior of the Kafka producer.

Default Behavior:
- The producer does not immediately send each message.
- It waits up to 1000 milliseconds (1 second) (linger.ms=1000) to batch messages before sending them to Kafka.
- This improves throughput by reducing the number of requests sent to the Kafka broker.

### ⚙️ Reducing the Lag (Optional Tuning)
You can reduce the delay by lowering the linger.ms value, which controls how long the producer waits before sending a batch:
`
kafka-console-producer.sh \
--bootstrap-server <broker>:9092 \
--topic <topic-name> \
--producer-property linger.ms=50`

This sends batches every 50 milliseconds, resulting in much faster delivery. While still batched, the delay becomes almost unnoticeable.

### ✅ Summary
Kafka producers batch messages by default for efficiency.
The lag observed is caused by the linger.ms setting in the producer.
This is not a performance issue with the Kafka broker or the consumer.
Adjusting the linger.ms property allows for more real-time behavior during development or testing.
