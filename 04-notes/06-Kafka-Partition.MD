# Kafka: Message Ordering and Scalability – Overview

Kafka ensures **ordered processing of messages** and supports **scalability** through its architectural concepts of **partitions** and **keys**.

This documentation is divided into:
- Partitions
- Keys and message routing
- Scalability
- Offsets
- Key selection strategy


# Kafka Partitions

## What Are Partitions?

- A Kafka **topic** is split into multiple **partitions**.
- Each partition is:
    - An **ordered sequence** of messages.
    - **Immutable** once written.
    - Processed **independently**.

## Purpose

- Allows Kafka to:
    - Scale horizontally.
    - Maintain message order **within a partition**.

## Default Behavior

- If partition count isn't specified at topic creation, Kafka assigns **one partition**.

# Message Keys and Ordering in Kafka

## Role of Keys

- Each message can include a **key** (e.g., account number, user ID).
- Kafka hashes the key and assigns the message to a **specific partition**.

## Partition Assignment

```text 
partition = hash(key) % number_of_partitions

Same key → Same partition → Ordering guaranteed

Example
All messages with key "A1" go to Partition 0.

All messages with key "A2" go to Partition 1.

Key Properties
Key can be:

- null

- String, integer, etc. 
```
---

### Partition algorithm used in Kafka (similar to java hashcode method) - 

```java
public static int partitionForKey(byte[] serializedKey, int numPartitions){
    return Utils.toPostive(Utils.murmur2(serializedKey)) % numPartitions;
}

```

### 📄 

```markdown
# Kafka Scalability Using Partitions

## The Problem

- Processing events sequentially limits scalability.

## Kafka's Solution

- Use **multiple partitions**
- Assign **different consumers** to different partitions

## Result

- **Parallelism**: Each consumer handles one partition
- **Isolation**: Messages for different keys are handled independently

## Example

- Partition 0 → Consumer 1 → Events for `A1`
- Partition 1 → Consumer 2 → Events for `A2`

Ordering per key is preserved. Processing can scale horizontally.

```
--- 
# Kafka Offsets

## What Is an Offset?

- A unique identifier for each message within a **partition**. 
- Note : It doesn't belongs to topic but to partition.
- Tracks consumer progress.

## Key Points

- Offsets are **per partition**, not per topic.
- Offset `0` in Partition 0 is different from Offset `0` in Partition 1.

## Example

```text
Partition 0: 0 → 1 → 2
Partition 1: 0 → 1 → 2

```

---

### 📄 `06-key-selection.md`

```markdown
# Choosing the Right Key in Kafka

## Why It Matters

- Key affects **partition assignment**
- Bad keys can lead to **load imbalance**

## Bad Key Examples

- Constant keys: `"2025-08-09"`, `"click"`
  - All messages go to the same partition for the same date

## Good Key Examples

- `user_id`, `account_id`, `transaction_id`
  - High variability = better distribution

## Goal

- Achieve **uniform distribution** across partitions
- Maintain **ordering** per key

```
---
# 🧠 Kafka Producer Partitioning Logic

## Who Calculates the Partition?

One critical detail in Kafka's architecture is that **partition assignment is handled by the producer client**, not the Kafka broker.

### ✅ Handled by the Kafka Client

- When you send a message using the Kafka producer:
    - If the message has a **key**, the client computes a **hash of the key**.
    - It then determines the partition using:

      ```text
      partition = hash(key) % number_of_partitions
      ```
      
    ```java
    public static int partitionForKey(byte[] serializedKey, int numPartitions){
    return Utils.toPostive(Utils.murmur2(serializedKey)) % numPartitions;
    }
    ```

- The client sends the message to the broker **with the partition already specified**.

> 📌 The Kafka broker does not decide the partition. It simply stores the message in the requested partition.

---

## ⚙️ Manual Partition Override

Kafka provides the flexibility to **manually override partition assignment**.

- Even if a key (e.g., `A1`) is hashed to Partition 0,
    - You can programmatically instruct Kafka to send it to Partition 1 instead.

### Use Cases for Manual Partitioning

- Custom load balancing
- Isolating specific types of events
- Advanced routing logic

> ⚠️ Use manual partitioning only when necessary, as it **bypasses Kafka’s default partitioning strategy**.

---

## 🔄 Default vs Manual Partitioning

| Mode              | Who decides?             | Based on                | Ordering guaranteed? |
|-------------------|--------------------------|--------------------------|-----------------------|
| Default           | Kafka client (producer)  | Key → hash → partition   | Yes, within a key     |
| Manual override   | You (application logic)  | Explicit partition index | Yes, within partition |

---

## ✅ Summary

- Kafka **producers decide** which partition a message goes to.
- Default behavior uses **key-based hashing**.
- You can **manually override** partition selection if needed.
- Kafka brokers simply **store the message** in the specified partition.


# 🧪 Kafka Demo: Consumer Group Behavior with Partition Reassignment

## 🔄 Initial Setup

- A Kafka topic with **2 partitions**.
- A single producer is sending messages with **various keys** (e.g., `key1`, `key2`, etc.).
- **Only one consumer** is initially active in the **consumer group**.

## 📥 Message Consumption (Single Consumer)

- Kafka assigns **all partitions** to the only active consumer.
- This consumer receives **all messages** from both partitions.
- Offset numbers may seem confusing (e.g., multiple `offset=0`), because:
  - **Each partition has its own offset sequence**.

---

## ➕ Adding a Second Consumer

- A second consumer joins the same consumer group (e.g., due to **auto-scaling**).
- Kafka performs **partition reassignment**:
  - Partitions are **redistributed** across both consumers.
- Now:
  - **Consumer 1** gets messages from **Partition 0**
  - **Consumer 2** gets messages from **Partition 1**

> 🎯 Messages with the same key will continue to go to the same partition, and thus to the same consumer.

### Example

- Messages with `key=5` always go to the same partition → always handled by the same consumer.

---

## ❌ Handling Consumer Failure

- If a consumer **dies or disconnects**, Kafka:
  - Detects the failure.
  - Triggers **another partition reassignment**.

### Result

- The remaining consumer takes over **all partitions** again.
- No messages are lost — processing continues with the surviving consumer.

---

## 🔁 Rejoining the Group

- If the second consumer **rejoins**, Kafka once again:
  - Rebalances partitions across both consumers.
  - Resumes parallel message processing.

---

## 📝 Summary

- Kafka uses **consumer groups** to manage scalability and fault tolerance.
- Each **partition is assigned to one consumer** within the group.
- Kafka automatically handles:
  - **Partition assignment** when consumers join
  - **Reassignment** when consumers leave or fail
- **Ordering is still guaranteed within each partition**, even during reassignments.







