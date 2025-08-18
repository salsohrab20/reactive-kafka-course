## 🧾 Kafka Partition Assignment Strategy: `CooperativeStickyAssignor`

---

### 🎯 Objective

Demonstrate how Kafka's **Cooperative Sticky Partition Assignment Strategy** behaves differently from the default strategy, especially during **consumer group rebalancing**.

---

### 🔁 Default Partition Assignment Behavior

* Kafka uses **`RangeAssignor`** by default.
* On consumer group changes (new consumer joins or leaves), Kafka:

    * **Revokes all partitions** from every consumer.
    * **Reassigns all partitions** across all consumers.
* This results in:

    * All consumers being temporarily paused.
    * Full partition reassignments, even if only one consumer change occurred.
    * Potential **consumer downtime or performance lag** during rebalancing.

---

### ⚙️ Cooperative Sticky Assignment

To reduce the disruption, Kafka provides:

```java
org.apache.kafka.clients.consumer.CooperativeStickyAssignor
```

Set it via config:

```java
props.put(ConsumerConfig.PARTITION_ASSIGNMENT_STRATEGY_CONFIG,
          CooperativeStickyAssignor.class.getName());
```

---

### ✅ Behavior with `CooperativeStickyAssignor`

#### 🔹 Initial State: 1 Consumer

* Consumer 1 starts alone:

    * Gets **all partitions (0, 1, 2)**.

#### 🔹 Adding Consumer 2

* Consumer 2 joins:

    * **Partition 2** is assigned to Consumer 2.
    * **Consumer 1 retains 0 and 1**.
    * Only **minimal partition reassignment**.

#### 🔹 Adding Consumer 3

* Consumer 3 joins:

    * Kafka evaluates current partition distribution.
    * Takes **Partition 1** from Consumer 1 and gives to Consumer 3.
    * **Consumer 2 remains untouched** (still has Partition 2).
    * Efficient and **non-disruptive rebalancing**.

#### 🛑 Stopping Consumers

* Consumers leaving the group also follow **incremental reassignment**.
* Remaining consumers **only take over what’s necessary**.
* No need to pause or reassign from unaffected consumers.

---

### 📌 Key Benefits of Cooperative Sticky Strategy

| Feature                      | Default (`Range`) | Cooperative Sticky   |
| ---------------------------- | ----------------- | -------------------- |
| Full partition revocation    | ✅ Yes             | ❌ No                 |
| Minimal reassignment         | ❌ No              | ✅ Yes                |
| Graceful scaling in/out      | ❌ No (disruptive) | ✅ Yes                |
| Better for high-availability | ❌ Risk of pause   | ✅ Seamless rebalance |

---

### 🔍 When to Use

* Critical systems where **consumer downtime must be minimized**.
* When adding/removing consumers frequently.
* Systems needing **gradual rebalancing** rather than full redistribution.

---

### 🧪 Demo Notes

* In logs, observe subtle changes in messages when using `CooperativeStickyAssignor`.
* Partition reassignments are **targeted and minimal**.
* Still **ensures balanced load** across consumers over time.

---

> 🧠 This strategy is especially useful in **microservice architectures** and **real-time streaming systems** where smooth, non-disruptive scaling is essential.

---


## 🧾 Kafka Partition Assignment Strategy: `RangeAssignor` (Default)

---

### 🔹 What Is the Default Assignment Strategy?

The **default partition assignment strategy** in Kafka is called:

```java
org.apache.kafka.clients.consumer.RangeAssignor
```

Or simply: **Range Assignment**

This is used **if no explicit strategy** is provided via consumer configuration.

---

### ⚙️ How `RangeAssignor` Works

1. **Partitions Are Sorted**

    * Kafka sorts all available partitions by name (e.g., `0, 1, 2, ...`).

2. **Consumers Are Sorted**

    * All consumers in the group are sorted by **`group.instance.id`** (if configured) or by **join order**.

3. **Partitions Are Divided**

    * Kafka then **evenly divides** partitions **in contiguous ranges** to each consumer.
    * The result is that **each consumer gets a *range* of partitions**, not random ones.

---

### 🧪 Example Scenario

#### ✔ Partitions: `0, 1, 2, 3, 4`

#### ✔ Consumers: `consumer-1`, `consumer-2`

After sorting:

* `consumer-1`: gets `0, 1`
* `consumer-2`: gets `2, 3, 4`

#### ✔ If a third consumer joins: `consumer-3`

* Sorted consumers: `consumer-1`, `consumer-2`, `consumer-3`
* Partition assignment:

    * `consumer-1`: `0`
    * `consumer-2`: `1, 2`
    * `consumer-3`: `3, 4`

⚠ **Note:** Due to range-based assignment, **some consumers may get more partitions** if the total count isn’t divisible evenly.

---

### 🔄 Rebalancing Behavior

* When a new consumer joins or leaves:

    * **All consumers are revoked from their partitions**
    * Kafka **reassigns partitions** from scratch based on sorted order.
    * This leads to **full rebalancing** and possible temporary unavailability.

---

### 🆚 RangeAssignor vs CooperativeStickyAssignor

| Feature                   | `RangeAssignor` (Default) | `CooperativeStickyAssignor` |
| ------------------------- | ------------------------- | --------------------------- |
| Partition distribution    | Contiguous ranges         | Sticky + balanced           |
| Rebalancing impact        | Full revoke + reassign    | Minimal movement            |
| Downtime during rebalance | Possible                  | Reduced                     |
| Use case                  | Simple, static consumers  | Dynamic, high-availability  |

---

### 🔧 Configuration (Optional Override)

```java
props.put(
  ConsumerConfig.PARTITION_ASSIGNMENT_STRATEGY_CONFIG,
  RangeAssignor.class.getName()
);
```

> 📌 This is usually **not necessary** unless you're explicitly changing from another strategy.

---
