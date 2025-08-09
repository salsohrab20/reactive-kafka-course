## 📥 Kafka Consumer: Pull-Based Model Explained

This section explains how the Kafka **consumer** works internally, specifically focusing on how messages are retrieved from a Kafka topic.

---

### 🔄 Is Kafka Consumer Push or Pull?

Kafka consumers follow a **pull-based model**.

- ✅ **Kafka does NOT push messages to consumers.**
- ✅ **Consumers explicitly pull (or poll) messages from Kafka.**

---

### ❓ Why Pull-Based?

You might wonder:
> *"Since the consumer is running, why can’t Kafka just push messages to it?"*

Here's why Kafka uses a pull-based approach:

- Kafka is designed for **high throughput** and **low latency**.
- It can easily handle **millions of messages per second**.
- Producers can write data much faster than consumers may be able to process.

📌 **Kafka has no way of knowing the speed or capacity of the consumer.**  
If it pushed messages to the consumer directly, it could easily **overwhelm** slower consumers.

By letting consumers **pull at their own pace**, Kafka ensures:

- Backpressure is managed.
- Consumers stay in control of how much data they receive.
- Overall system stability is maintained.

---

### ⚙️ How Polling Works

The consumer repeatedly polls Kafka for new messages:

1. "Can you give me some messages?"
2. Kafka responds with the requested number of records (up to a configured limit).
3. Consumer processes them.
4. Then it polls again for more.

This polling loop is continuous and **controlled by the consumer**.

---

### 🔧 Tuning with `max.poll.records`

Kafka allows you to control how many messages a consumer should receive per poll using the `max.poll.records` configuration.

- **Default**: `500`
- **Configurable**: You can increase or decrease this based on your consumer’s capacity.

### properties
# In consumer properties 
-  max.poll.records=500 

```This gives you fine-grained control over: How many records are fetched in one request. How much work the consumer handles in each poll cycle. ```

### 🧠 Similarity to Reactive Streams
This is conceptually similar to Reactive Streams and Publisher-Subscriber patterns.
A subscriber must explicitly request (n) items from the publisher.
Similarly, a Kafka consumer must poll for messages from Kafka.

#### This model ensures:
 - Controlled flow of data 
 - Avoidance of memory overflow or processing overload

### ✅ Summary
Kafka consumers pull data — Kafka does not push messages.
This design supports scalability, backpressure, and fault-tolerance.
The number of messages per poll is controlled via max.poll.records.
The consumer decides when and how much data it wants to receive.

💡 Pro Tip: Tune max.poll.records and other consumer settings based on your application's processing speed and latency requirements.

---

### **Kafka Consumer Groups Demonstration Summary:**

1. **Two Consumers from Different Groups:**

    * One consumer is started from the **Payment Service (PS)** group.
    * Another consumer is started from the **Inventory Service** group.
    * A producer sends messages.
    * **Result:** Both consumers (from different groups) receive **all messages** because Kafka delivers messages to **each group independently**.

2. **Adding a Second Consumer to the Same Group (Inventory Service):**

    * A new consumer is added to the **Inventory Service** group.
    * Now, Inventory Service group has **two consumers**.
    * When a message is sent:

        * **Only one of the two consumers** in the Inventory Service group receives it.
        * This is due to **load balancing** within a consumer group: Kafka distributes messages across consumers **in the same group**.

3. **Observed Issue:**

    * One consumer in the group appears idle.
    * Kafka is distributing messages, but not all consumers are getting messages because of **partition assignment** rules.
    * **Solution hint:** Use **partitions** to enable parallel processing and better distribution.

4. **Console Consumer Behavior Without Explicit Group:**

    * When using Kafka console consumers **without specifying a group**, each instance **automatically gets its own consumer group**.
    * As a result, **each console consumer gets all the messages**, because they are treated as separate groups.

---
### Scenario 1: Consumers in Different Groups (All receive messages)

```Topic: orders
+-----------------+
|     Producer    |
+--------+--------+
|
Sends Messages
|
------------------------------------------
|                                        |
+----v----+                              +----v----+
|Consumer | (Group: Payment Service - PS)|Consumer | (Group: Inventory Service - IS)
+---------+                              +---------+
```
→ Both consumers receive ALL messages independently.

### 🔸 Scenario 2: Multiple Consumers in the Same Group (Load Balanced)
```
Topic: orders (1 Partition for simplicity)
+-----------------+
|     Producer    |
+--------+--------+
|
Sends Messages
|
v
Group: Inventory Service (IS)
+----------------+    +----------------+
|   Consumer 1   |    |   Consumer 2   |
+----------------+    +----------------+
```

→ Kafka assigns the partition to only ONE consumer at a time.
→ Only one of them gets each message.
→ The other may stay idle.

### 🔸 Scenario 3: Console Consumers without Group (Each Gets Own Group)

```Topic: orders
+-----------------+
|     Producer    |
+--------+--------+
|
Sends Messages
|
------------------------------------------
|                                        |
+----v----+ (Group: **ConsoleConsumer**#1)  +-----v----+ (Group: **ConsoleConsumer**#2)
|Consumer |                             |Consumer  |
+---------+                             +----------+
```
→ Kafka sees them as different groups.
→ Each consumer receives ALL messages.

### ✅ Key Takeaways:
- Different groups: All get the same messages (good for independent services). 
- Same group: Kafka load-balances messages (good for scaling within one service). 
- No group (console): Treated as unique groups → all messages received by each.

# 📚 Kafka Scenarios: Partition Count vs. Consumer Scaling

This section covers real-world Kafka behavior and edge cases related to **consumer scaling**, **partition reassignment**, and **dynamic partition changes**.

---

## 🔁 Scenario 1: Scaling Consumers in a Consumer Group

### 🧩 Setup

- 1 **topic** with **3 partitions**
- 1 **consumer group**
- Initially, **1 consumer**

### Behavior

| Consumers in Group | Kafka Behavior                             |
|--------------------|---------------------------------------------|
| 1                  | All 3 partitions assigned to the consumer   |
| 2                  | 1 partition reassigned to the new consumer  |
| 3                  | 1 partition per consumer (balanced)         |
| 4+                 | Extra consumers remain **idle**             |

> ⚠️ **Kafka does not assign a single partition to multiple consumers**, to maintain **message ordering**.

### 💡 Rule of Thumb

> ✅ **Max number of active consumers = number of partitions**

---

## 🔄 Scenario 2: Increasing Partition Count After Production

### Setup

- Initially, topic has **3 partitions**
- Messages are keyed (e.g., `key1`, `key2`, etc.) and mapped deterministically using Kafka's `murmur2` hash
- Messages are being produced and consumed correctly

### Problem

- You realize more throughput is needed, so you run a command to **increase partitions to 4**
- New messages may now get assigned to the **new 4th partition**

### Consequence

- This can **break message ordering** for a given key!
- Example: A message with `key=4` initially went to Partition 2, now starts going to Partition 3
- Older message (from original partition) might be processed **after** the new one → **ordering violation**

---

## ⚠️ Important Caveats of Changing Partition Count

| Issue                            | Impact                         |
|----------------------------------|--------------------------------|
| Repartitioning after production  | Breaks message key ordering    |
| Consumers rebalance              | Partitions reassigned properly |
| Extra consumer after limit       | Stays idle                     |

---

## 🛠️ Solutions to Handle Partition Increase

### ✅ 1. Design Upfront

- Plan the **number of partitions ahead of time**
- Avoid repartitioning after production has started

---

### ✅ 2. Accept Short-Term Ordering Issues

- If message ordering is **not critical**, it's acceptable to:
   - Tolerate reordering for a short period
   - Let the producer continue sending to the topic

---

### ✅ 3. Stop Producer → Drain → Restart

- Steps:
   1. **Stop the producer**
   2. Let consumers **drain** all current partitions
   3. Increase partition count
   4. Restart the producer

- Ensures clean transition and **preserves ordering**

---

### ✅ 4. Create a New Topic

- Best option for **zero disruption** and **no ordering issues**
- Steps:
   1. Create a **new topic** with more partitions
   2. Update producer to write to the **new topic**
   3. Allow consumers to finish processing old topic
   4. Update consumers to consume from the **new topic**
   5. Delete the old topic once fully drained

---

## ✅ Summary

- Kafka partitions determine how many consumers can be active in a group
- **Repartitioning after production begins can break ordering**
- There are **multiple strategies** to handle this:
   - Plan partitioning upfront
   - Stop the producer and drain
   - Accept short-term ordering trade-offs
   - Migrate to a new topic

> Choose a strategy based on **your application’s tolerance for message reordering and downtime**.
