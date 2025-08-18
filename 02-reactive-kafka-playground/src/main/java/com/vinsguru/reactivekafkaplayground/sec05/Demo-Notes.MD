#### 🎯 Objective

Demonstrate how Kafka **distributes partitions** across multiple **consumer instances** in a **consumer group**, and how **rebalancing** works when consumers join/leave.

---

### 🛠️ Setup Overview

### 📝 Producer Setup

* Copied producer logic from `section02`.
* Emits values at **50ms interval**:

  ```java
  Flux.interval(Duration.ofMillis(50))
  ```
* Emits a total of **10,000 items**:

  ```java
  .take(10_000)
  ```

> This gives enough time to observe partition rebalancing in action.

---

### 🧑‍💻 Consumer Setup

#### 🔁 Refactored Entry Point

* Replaced `public static void main()` with:

  ```java
  public static void startConsumer(String instanceId)
  ```
* Passed `instanceId` to uniquely identify each consumer.

#### 🧩 Created `KafkaConsumerGroup` class

* Contains **three nested static classes**:

  ```java
  private static class Consumer1 { public static void main(...) }
  private static class Consumer2 { public static void main(...) }
  private static class Consumer3 { public static void main(...) }
  ```

* Each calls:

  ```java
  KafkaConsumer05.startConsumer("instance-1");
  KafkaConsumer05.startConsumer("instance-2");
  KafkaConsumer05.startConsumer("instance-3");
  ```

* This allows simulating **three separate JVMs/consumers** manually.

> ⚠️ IntelliJ users can also use *parallel run*, but this method works on all environments, including CLI.

---

### 🧵 Kafka Topic Setup

* Created a topic with **3 partitions**:

  ```bash
  kafka-topics.sh --create --topic order-events \
    --bootstrap-server localhost:9092 \
    --partitions 3 --replication-factor 1
  ```

* Deleted old topic:

  ```bash
  kafka-topics.sh --delete --topic events --bootstrap-server localhost:9092
  ```

> 🧠 Kafka **distributes partitions** across consumer instances **within the same group**.
> If you run 3 consumers and have 3 partitions, each consumer will get **1 partition**.

---

### 📈 Expected Behavior

| Scenario | Partitions | Consumers | Result                                                  |
| -------- | ---------- | --------- | ------------------------------------------------------- |
| 3        | 1          | 3         | All 3 consume from the **same** partition (shared load) |
| 3        | 3          | 3         | Each consumer gets **1 unique partition**               |
| 3        | 2          | 3         | Kafka rebalances: 1 consumer gets **no partition**      |

---

### 🧪 Observing Rebalancing

* When starting/stopping consumers dynamically:

    * Kafka will **rebalance** partition assignments.
    * You’ll see log messages indicating re-subscription and reassignment.
    * Great for testing fault tolerance and load balancing.

---

### 🏁 Summary

* ✅ Created a demo with multiple consumer instances.
* ✅ Used **instance IDs** to differentiate consumers.
* ✅ Observed Kafka's **rebalance behavior** in action.
* ⚙️ Make sure your topic has enough partitions to distribute among consumers.

> 💡 Key takeaway: Kafka ensures that **each partition is consumed by only one consumer within a group**, enabling **horizontal scalability**.

---


#### 🎯 Goal

Observe how Kafka **assigns and reassigns partitions** dynamically when **multiple consumers** in the **same group** start and stop.

---

### 🧪 Steps & Observations

#### ✅ Start Consumer 1

* With **only one consumer**, **all partitions (0, 1, 2)** are assigned to it.
* Since it's the sole member of the group, it handles all partitions.
* Producer starts emitting at **50ms interval**.

  * Note: This may be **too fast** to clearly observe logs in real-time. You can increase the interval if needed.

#### ✅ Start Consumer 2

* **Rebalancing occurs**:

  * **Consumer 1**:

    * Partitions 0 & 1
  * **Consumer 2**:

    * Partition 2
* Kafka logs show:

  * **Consumer 1** revokes all partitions.
  * Kafka reassigns:

    * Partitions 0 & 1 to Consumer 1
    * Partition 2 to Consumer 2
* Old messages (e.g., event 12, 13, etc.) are not lost — just redistributed.

#### ✅ Start Consumer 3

* Another rebalance:

  * Kafka reassigns:

    * Consumer 1: Partition 0
    * Consumer 2: Partition 1
    * Consumer 3: Partition 2
* Partition distribution is now **even** (1 partition per consumer).
* Each consumer gets **roughly ⅓ of the workload**.

#### ❌ Stop Consumer 3

* Kafka detects the consumer has left (after a delay — depends on **session timeout**).
* Rebalance happens again:

  * Partitions are reassigned.
  * For example:

    * Consumer 2 may now get back **Partition 2**.
* No data is lost — Kafka tracks the offsets and hands off ownership.

#### ❌ Stop Consumer 2

* Only **Consumer 1** remains.
* Kafka reassigns **all partitions (0, 1, 2)** back to Consumer 1.
* Now Consumer 1 will consume messages from **all partitions again**.

---

### 🔄 Rebalancing Summary

| Action                     | Result                              |
| -------------------------- | ----------------------------------- |
| Start new consumer         | Rebalance: partitions redistributed |
| Stop a consumer            | Rebalance: partitions reassigned    |
| Faster consumer join/leave | Requires observing logs quickly     |

---

### 📌 Key Takeaways

* ✅ Kafka ensures **each partition is assigned to exactly one consumer** in a group.
* 🔁 When consumers **join or leave**, Kafka **rebalances** partition assignments.
* 🧠 Offsets are **not lost**; processing resumes from where the previous consumer left off.
* ⚙️ Producer **does not care** about rebalancing; it continues sending to Kafka.
* 🧭 For better log visibility, **increase the delay between messages** if needed.

---

### 🧪 Troubleshooting Tips

* Can't see rebalancing logs?

  * Try **scrolling slowly** in the log window.
  * Wait for **session timeout (\~10s)** if stopping a consumer.
  * Increase message delay to observe step-by-step behavior.

---

> 🧠 Understanding rebalancing is crucial for building resilient, scalable Kafka consumers.

