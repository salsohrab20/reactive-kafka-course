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

# Kafka Consumer Delay: Understanding the 45-Second Wait

## 🕒 Why the Delay?

When restarting a Kafka consumer application, you may notice a ~45-second delay before it starts consuming messages again. Here's what's happening behind the scenes.

---

## 🧠 What's Happening Internally?

- When the consumer starts, it attempts to **join a consumer group**.
- Kafka logs show messages like:  
  `Request joining group...`  
  `Group member needs a valid member ID`  
  `Rebalance failed...`
- Kafka is waiting to **rebalance** the consumer group because it’s not sure if the previous consumer is still alive.

---

## 🧩 Why the Confusion?

- The topic has **only one partition**, and it's already assigned to a consumer.
- On restart, Kafka sees a new instance (new member ID) trying to join the same group.
- Kafka doesn't immediately revoke the partition from the old consumer — it **waits**.

### ⏱️ Default Behavior

- Kafka waits based on the `session.timeout.ms` config (default: ~45 seconds).
- It assumes the old consumer might still come back.
- Only after this timeout does Kafka consider the old consumer "dead" and reassigns the partition.

---

## ✅ The Fix: Use a Stable Instance ID

To avoid the 45-second wait:

- Set a **static group instance ID** using `group.instance.id`.
- This gives your consumer a **stable identity** within the group.

### Example:
```java
consumerConfig.put(ConsumerConfig.GROUP_INSTANCE_ID_CONFIG, "instance-1");
```
```This tells Kafka:
“I am the same member of this group every time I connect.”
```

### ⚡ Result
- First start: Kafka still waits (it's a new ID).
- Subsequent restarts: Reconnection is instant, no rebalance needed.

#### Demo:
- Run the app with group.instance.id = "instance-1" → Wait 45s.
- Restart the app → Reconnection is immediate.

### ⚠️ Note on Duplicate Deliveries
- With the same consumer group ID and member ID:
- Kafka may deliver the same messages again on each restart.
- This happens if offsets are not committed properly.

# 🌀 Why Kafka Delivers the Same Events Again and Again

## 🤔 The Problem

When using a Kafka consumer (especially with the Reactor Kafka library), you might observe:

> 🔁 Kafka keeps delivering the **same events** to the **same consumer group** after every restart.

This behavior is **confusing**, especially if you didn’t see it with the Kafka console consumer.

---

## 🔍 Root Cause: Acknowledgement and Offsets

### How Kafka Works

- Kafka tracks **offsets per consumer group**.
- A **consumer** receives events from a **Kafka partition**.
- But unless the **offset is committed**, Kafka thinks:
  > "The consumer didn’t process anything."

### Offset Breakdown

- **Log End Offset**: Total number of events in a partition.
- **Current Offset**: The last acknowledged message ID.
  - If current offset = 0, Kafka assumes **nothing has been processed**.

So:
- On every restart, Kafka sees offset `0` and sends **all events again**.

---

## ✅ Solution: Acknowledge After Processing

To move the offset forward, the consumer **must acknowledge** each event **after processing** it.

```java
record.receiverOffset().acknowledge();
```

## 🔄 Acknowledge After Processing, Not Before
```Why?
Imagine processing an event takes time (e.g. 1 minute). If you acknowledge first and then crash, Kafka assumes the event is processed — but it's lost! If you acknowledge after processing, the system is more reliable and resilient.
```
### 🧪 Console Consumer vs. Programmatic Consumer
- Console Consumer: Auto-acknowledges behind the scenes.
- Custom Code (Reactor Kafka): You must manually acknowledge.

### ⚠️ Gotcha: The Commit Interval
Even after you call .acknowledge(), Kafka might still re-send events briefly. Why?
Kafka batches acknowledgments and commits offsets periodically, not immediately.

### 🔁 Example:
Kafka has `auto.commit.interval.ms (default: 5000ms = 5 seconds)`.
```
During this interval, acknowledged offsets may not yet be committed.
If your app crashes/restarts quickly, you might get the same events again.
```

### 🛠️ Recap: How to Avoid Duplicate Deliveries
✅ Acknowledge events manually after processing.
🕒 Understand the impact of auto.commit.interval.ms.
♻️ Don’t rely on console behavior — it hides complexity.
🚫 Don’t acknowledge before processing.

## 📝 Summary

| Concept               | Explanation                                          |
| --------------------- | ---------------------------------------------------- |
| Offset                | Position of a consumer in a Kafka partition          |
| Acknowledge           | Tells Kafka “I processed this message”               |
| No Acknowledgement    | Kafka assumes consumer didn’t process — resends      |
| Acknowledge Too Early | Message might be lost if the app crashes             |
| Commit Interval       | Delay between acknowledging and actual offset commit |

# ⚙️ Kafka Auto-Commit vs. Manual Acknowledgement

## 🧾 What If You Don't Want to Acknowledge Manually?

Kafka provides an option to **automatically commit offsets** without manual acknowledgement.

### 🔧 Property: `enable.auto.commit`

- **Default**: `false`
- **Set to `true`** to enable automatic offset commits.

```java
ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG = "true"
```
### ✅ Summary

| Method                    | Description                                         | Control | Risk of Data Loss |
| ------------------------- | --------------------------------------------------- | ------- | ----------------- |
| `enable.auto.commit=true` | Kafka commits offsets periodically (automatically)  | Low     | Higher            |
| Manual Acknowledgement    | You explicitly commit after processing each message | High    | Lower             |

# Kafka Consumer Scenario

Let’s say we’ve built a consumer application that processes credit card events.

## Message Flow:

1. The app requests messages from the Kafka broker.
2. It receives and processes the messages — for example, charging users.
3. However, before sending an acknowledgment to Kafka, something goes wrong:
  - A network issue occurs, or
  - The server restarts.

## What Happens Next?

- After restarting, if the app asks Kafka for messages again, **Kafka will re-deliver the same messages** because it **never received the acknowledgment**.
- This means the app might **process and charge users a second time**.

## Key Takeaway:

Kafka guarantees **at-least-once** delivery by default, so duplicates can happen if acknowledgments fail.

---

## Out of Order Commit

# Kafka Consumer Acknowledgement Scenario

Let’s explore another Kafka scenario involving message acknowledgments.

## Setup

- **Kafka Broker** and **Kafka Consumer** are running.
- There’s one topic with **millions of messages**.
- Kafka delivers messages **in batches**, not all at once.

## Scenario

1. The consumer requests messages.
2. The broker delivers **messages 1, 2, 3, and 4**.
3. The consumer processes the messages as follows:
  - **Message 1**: Processed, **not acknowledged**
  - **Message 2**: Processed, **not acknowledged**
  - **Message 3**: Processed, **not acknowledged**
  - **Message 4**: Processed, **acknowledged**
4. Then, the **server crashes** or restarts.
5. After restart, the consumer requests messages again.

## What Will Kafka Deliver?

- Kafka will **start delivering from message 5 onward** (e.g., 5, 6, 7, etc.).
- Why?
  - Kafka uses **acknowledgments as bookmarks** to track the consumer’s progress.
  - Since **message 4 was acknowledged**, Kafka assumes that messages 1–4 were successfully processed.
  - Therefore, it skips those and delivers the next messages.

## Key Point

> The **last acknowledged message** tells Kafka where to resume delivery from.

Understanding this helps in designing systems that are resilient and avoid reprocessing already-handled messages.




