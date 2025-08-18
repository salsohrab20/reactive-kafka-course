#### 🎯 Objective

Demonstrate how to **add custom headers** to Kafka messages and **read them** on the consumer side using **Reactor Kafka**.

---

### 📝 Producer Updates

#### 🧪 Added Custom Headers

* Created a new method to build `SenderRecord` with headers:

  ```java
  SenderRecord<String, String, String> createSenderRecord(Integer i) {
      RecordHeaders headers = new RecordHeaders();
      headers.add("client-id", "some-client".getBytes());
      headers.add("trace-id", "123".getBytes());

      ProducerRecord<String, String> producerRecord = 
          new ProducerRecord<>(topic, null, "key-" + i, "value-" + i, headers);

      return SenderRecord.create(producerRecord, null);
  }
  ```

* Used this method in the producer pipeline:

  ```java
  Flux.range(1, 10)
      .map(this::createSenderRecord)
      ...
  ```

---

### 🖥️ Consumer Updates

* Updated `doOnNext()` to print headers for each message:

  ```java
  receiverRecord.headers().forEach(header -> {
      log.info("Header Key: {}, Value: {}", 
          header.key(), new String(header.value()));
  });
  ```

* Also prints the usual key and value:

  ```java
  log.info("Key: {}, Value: {}", record.key(), record.value());
  ```

---

### ✅ Sample Output

```
Key: key-1, Value: value-1
Header Key: client-id, Value: some-client
Header Key: trace-id, Value: 123
...
```

---

### 🔍 Notes

* **Header format**: Kafka headers are sent as **key-value byte arrays**.
* You must convert `byte[]` values to strings (or appropriate types) in the consumer.
* Headers can include metadata like:

    * `client-id`
    * `trace-id`
    * `correlation-id`
    * Any app-specific data

---

### 🏁 Summary

| Component             | Purpose                            |
| --------------------- | ---------------------------------- |
| `RecordHeaders`       | Add custom headers in producer     |
| `headers().forEach()` | Access and log headers in consumer |
| Header values         | Are byte arrays, must be converted |

> ✅ Use Kafka headers to enrich messages with metadata
> 📦 Keeps payload clean and separates concerns

