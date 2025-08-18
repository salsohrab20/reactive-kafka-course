### 📘 Notes: Kafka Performance Demo – Producing & Consuming 1 Million Events

#### 🎯 Objective

Demo to test how fast we can produce and consume **1 million Kafka events** using **Reactor Kafka**.

---

### 🧪 Test: Emit 1 Million Events

#### ✅ Producer

* Used `Flux.range(1, 1_000_000)` to emit 1 million items.
* Tracked time using:

  ```java
  long startTime = System.currentTimeMillis();
  ...
  doOnComplete(() -> {
      long totalTime = System.currentTimeMillis() - startTime;
      logger.info("Total time taken: {} ms", totalTime);
  });
  ```
* Note: Start time is captured before sender creation, but this overhead is negligible for our purpose.

---

#### ✅ Consumer

* Just runs in parallel to consume incoming Kafka messages.

---

### 📊 Result (Default Config)

* Time taken to emit **1 million items**: \~**10.6 seconds**
* The last emitted item was nearly in sync with the last consumed item.
* Shows good throughput, minimal delay.

---

### ⚙️ Optimization: `max.in.flight`

* Modified sender config:

  ```java
  .maxInFlight(10_000)
  ```
* Meaning: Up to **10,000 messages** can be in-flight (unacknowledged) at the same time.

#### 📈 Result with Optimization

* Time taken: **\~3 seconds** for 1 million events.
* Massive improvement in throughput.
* Producer and consumer kept up with minimal lag.

---

### 🤔 Questions That Arise

* What does `max.in.flight` really do?
* Can we push further?

    * e.g., produce **5 million events** instead of 1 million?
* What are the practical implications or limits?

---

### 📝 Summary

| Test Condition        | Time Taken |
| --------------------- | ---------- |
| Default Config        | \~10.6 sec |
| `max.in.flight = 10k` | \~3.0 sec  |

* Increasing `max.in.flight` boosts throughput significantly.
* Reactive Kafka handles large volumes efficiently when tuned.
* Performance tuning like this is critical for high-volume event streaming apps.

---

#### 🎯 Purpose

`max.in.flight` controls how many Kafka records can be **in-flight (unacknowledged)** at a time in a **reactive Kafka sender**. Tuning this parameter can significantly improve throughput — but it must be used with care.

---

### 🧠 Concept Breakdown

#### 🔁 Reactive Streams & Backpressure

* Reactive systems follow **backpressure** — data is only emitted when the **subscriber** is ready.
* This ensures the system doesn't get overwhelmed and can **scale gracefully**.

https://www.vinsguru.com/reactor-limitrate-example/

#### 🔍 Prefetch / Limit Rate

* Internally, the reactive stream uses a **prefetch size** (a buffer/queue).
* **Default** prefetch/limit rate: `256`

  * This means the source (e.g., `Flux.range`) will emit 256 items and **pause** until the subscriber processes them.
* This internal queue is **not Kafka-related**, but managed **within the JVM**, between the `Flux` and the Kafka sender.

#### ⚙️ `max.in.flight` Behavior

* Example:

  ```java
  SenderOptions.create()
      .maxInFlight(10_000)
  ```
* This controls **how many records** can be concurrently sent to Kafka without waiting for acknowledgments.

#### 🔼 What Happens When You Increase It?

* More items are **prefetched** and sent **faster**, leading to **higher throughput**.
* Example: Setting `max.in.flight = 10_000` reduced the time to emit **1 million messages** from \~10.6s to \~3s.

---

### ⚠️ Trade-offs & Caution

* Increasing `max.in.flight` means **more data held in memory** (pending acknowledgment).
* Large values (e.g., millions) could lead to:

  * **Out of Memory (OOM)** errors
  * Increased **latency** in error handling and recovery

---

### 📌 Summary

| Parameter             | Default         | Effect                                   |
| --------------------- | --------------- | ---------------------------------------- |
| `max.in.flight`       | `256`           | Controls concurrent unacknowledged sends |
| High value (e.g. 10k) | Faster emission | Better throughput, higher memory usage   |
| Very high value       | Risk of OOM     | May overload JVM memory                  |

> ✅ Use `max.in.flight` to **boost performance**
> ⚠️ But **monitor memory** and test for **your specific use case**

---
