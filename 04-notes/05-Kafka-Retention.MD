## 🗃️ Kafka Log Retention Policy

Kafka stores messages on disk, but it doesn't keep them **forever** by default. The retention of these messages is governed by a configurable **log retention policy** (we can see this in docker container server.properties).

---

### ⏳ How Long Does Kafka Keep Data?

By default, Kafka retains data for:

- **7 days** (168 hours)
  ```properties
  log.retention.hours=168
  ```

### You can also configure retention based on log size:

For example:
 ```properties
   log.retention.bytes=<max-bytes> 
   ```
Kafka will delete log segments when either condition is met — time-based or size-based.

### 🔄 Retention Check Interval
Kafka periodically checks whether any log segments need to be deleted. This interval is controlled by:
 
```properties
    log.retention.check.interval.ms=300000  # default: 5 minutes
```
During each interval, Kafka checks:

- Has any log segment exceeded the retention time?
- Has the total log size exceeded the configured threshold?
- If so, it deletes the oldest segments accordingly.

### ✅ Summary
Kafka does not retain data indefinitely.

Data is deleted based on time (log.retention.hours) or size (log.retention.bytes).

The cleanup process runs periodically as configured by log.retention.check.interval.ms.

You can modify these settings in the server.properties file (even inside a Docker container).
