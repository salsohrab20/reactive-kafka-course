# 🧠 Kafka Section Summary

## 📌 What is Kafka?

Kafka is a **distributed event streaming platform** that enables real-time data pipelines and streaming applications. Key characteristics:

- High throughput and low latency
- Horizontally scalable
- Events are durable and stored across multiple **brokers** in a **Kafka cluster**

---

## 🗂 Topics and Partitions

- **Topics** are categories for messages/events.
- Each topic can have **multiple partitions** for scalability and parallelism.
- Every message in a partition has a unique **offset**.

---

## ⚙️ Kafka Cluster Architecture

- A **Kafka cluster** is a group of Kafka servers.
- Each server is either a:
    - **Controller**: manages metadata and coordination.
    - **Broker**: handles client interactions and data storage.

### 🧠 Leader & Follower Partitions

- Each partition has:
    - One **leader** (handles all reads/writes)
    - Zero or more **followers** (replicate data from leader)
- If the leader node fails, a follower is promoted.

---

## 🛑 Retention Policy

- Kafka **stores data on disk**.
- Data retention is managed via the **log retention policy**.
    - Prevents running out of disk space.
    - Configurable based on size or time (e.g., retain for 7 days).

---

## 🚀 Kafka Bootstrapping

- **Bootstrap servers**: Small set of brokers used to connect to the entire cluster.
- Application needs to reach only one bootstrap server to discover the full cluster.

---

## 👥 Consumer Groups

- A **Consumer Group** represents a logical group of consumers (e.g., a microservice).
- Each group gets a **copy of the message**.
- Kafka guarantees:
    - Each message is delivered to only **one consumer** within a group.
    - Multiple groups can independently consume the same topic.

### Use Case Examples

- `InventoryService` → Consumer Group A
- `PaymentService` → Consumer Group B

---

## 📊 Kafka Message Lifecycle

1. **Producer** sends a message (with optional key).
2. Kafka routes it to a partition (based on key or round-robin).
3. **Consumer** receives it **only after acknowledging** processing.
4. Kafka tracks:
    - Consumer offsets
    - Lag (messages not yet consumed)

---

## 📦 Kafka Message Structure

| Attribute        | Description                             | Notes                              |
|------------------|-----------------------------------------|------------------------------------|
| **Key**          | Used for partitioning (optional)        | Can be null                        |
| **Value**        | The actual event/data                   | Required                           |
| **Timestamp**    | When the event was created/sent         | Auto-set or manually assigned      |
| **Partition**    | Which partition the message belongs to  | Auto or manually assigned          |
| **Offset**       | Message position in the partition       | Assigned by Kafka                  |
| **Headers**      | Metadata for tracing/context            | Optional                           |
| **Compression**  | Saves disk/network usage                | e.g., gzip, snappy, none (default) |

---

## ✅ Acknowledgment Model

- Kafka **waits for acknowledgment** from the consumer after delivering a message.
- Only after acknowledgment is the message considered **successfully consumed**.
- This ensures **at-least-once delivery**.
- Console consumers skip this logic (used for testing/demo only).

---