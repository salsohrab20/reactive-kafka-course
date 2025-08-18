## 🧾 Kafka Consumer Offset Seeking in Reactor Kafka

---

### 🎯 Goal

To demonstrate how to **manually seek** offsets in a Kafka consumer using **Reactor Kafka**.

This is useful when:

* You **don’t want to start from `earliest` or `latest`**
* You want to **replay specific data**, such as:

    * Last *N* records from each partition
    * All records from a specific partition only
    * Records from a specific timestamp

---

### 📁 Setup

* Topic: `order-events`
* Partitions: `3`
* Data: 10,000 events already produced

---

### 🧩 How to Seek Offset in Reactor Kafka

1. **Use `addAssignListener()`**

    * Triggered when partition(s) are assigned to the consumer
    * Useful to perform seek operations once assignment is done

   ```java
   receiverOptions.addAssignListener(partitions -> {
       for (ReceiverPartition p : partitions) {
           long offset = p.position() - 2; // Seek to last 2 messages
           p.seek(offset);
       }
   });
   ```

2. **Output**

   ```
   Assigned partition: topic=order-events partition=2
   Current offset: 3419
   Seeking to offset: 3417
   ```

    * This will emit the **last 2 records from each partition**

---

### 🧪 Targeting a Specific Partition

Instead of seeking on *all partitions*, you can filter one:

```java
receiverOptions.addAssignListener(partitions -> {
    partitions.stream()
        .filter(p -> p.topicPartition().partition() == 2)
        .findFirst()
        .ifPresent(p -> p.seek(p.position() - 2));
});
```

This will:

* Seek only **partition 2**
* Start from **2 records before current position**

---

### 🛑 Important Notes

* ❗ **Offset must not be negative**:

    * Always validate `p.position()` before subtracting
    * Otherwise, Kafka will throw an error

* 🧰 Other useful methods:

    * `p.seek(long offset)`
    * `p.seekToBeginning()`
    * `p.seekToEnd()`
    * `p.seekToTimestamp(long timestamp)` *(for time-based replay)*

---

### ✅ Summary

Kafka consumer `seek()` is powerful when you want to:

* Replay messages from a known point
* Debug or test specific partitions
* Re-consume data with precise control

This gives much finer control than just setting `auto.offset.reset = earliest|latest`.

---

