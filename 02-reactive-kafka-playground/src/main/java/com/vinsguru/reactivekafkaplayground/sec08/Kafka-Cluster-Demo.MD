# Kafka Cluster Setup with Docker Compose

In this section, we’ll set up a **Kafka cluster with KRaft mode using Docker Compose**. We'll run **three Kafka nodes** (containers) in a Docker network to simulate a real Kafka cluster with controller, broker, and client communication.

---

## 🧠 Overview of Architecture

* **Three Kafka containers**: `kafka-1`, `kafka-2`, `kafka-3`
* **Controller & Broker Communication**: Happens internally over Docker network
* **External Communication**: Between Kafka and producer/consumer apps, mapped to host machine ports

---

## 🔌 Types of Kafka Communication

| Type                 | Participants                        | Purpose                           | Scope    |
| -------------------- | ----------------------------------- | --------------------------------- | -------- |
| Control Plane        | Controllers                         | Leader election, cluster metadata | Internal |
| Data Plane           | Brokers                             | Partition replication             | Internal |
| Client Communication | Producers/Consumers ↔ Kafka Brokers | Produce/Consume messages          | External |

---

## ⚙️ Docker Compose Setup

### 🐳 Services

* **Three services**: `kafka-1`, `kafka-2`, `kafka-3`
* Each uses the same Kafka image
* Unique:

    * `container_name`
    * `ports` mapping (e.g., 8081, 8082, 8083)
    * `node.id`
    * `config file` (S1.properties, S2.properties, S3.properties)
    * `log directory`

### 📁 Directory Mapping

```yaml
volumes:
  - ./configs/S1.properties:/opt/kafka/config/kraft/server.properties
  - ./data/b1:/tmp/kafka-logs
```

> ⚠️ Each container must have a **unique log directory** to avoid conflicts.

---

## 🔧 Kafka Configuration (Example: `S1.properties`)

### 🔢 Cluster ID

All nodes must share the **same `cluster.id`**:

```properties
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@kafka-1:9093,2@kafka-2:9093,3@kafka-3:9093
```

---

### 🔊 Listeners

Kafka can listen on multiple ports for different purposes:

```properties
listeners=INTERNAL://:9092,CONTROLLER://:9093,EXTERNAL://:8081
listener.security.protocol.map=CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
inter.broker.listener.name=INTERNAL
controller.listener.names=CONTROLLER
```

> Listener names like `INTERNAL`, `CONTROLLER`, `EXTERNAL` are **custom labels** – you can name them anything, but they must be consistent across properties.

---

### 🌐 Advertised Listeners

Specify how **other nodes or clients** should reach this Kafka container:

```properties
advertised.listeners=INTERNAL://kafka-1:9092,EXTERNAL://localhost:8081
```

* Internal traffic: uses Docker network hostname (`kafka-1`)
* External clients: use `localhost` and the mapped host port

> Think from the **caller’s perspective** when setting advertised listeners.

---

### 🛡️ Security Protocols

Kafka supports different protocols:

* `PLAINTEXT`: No encryption/authentication
* `SSL`: TLS encryption
* `SASL_PLAINTEXT`: Authentication only
* `SASL_SSL`: Both authentication and encryption

In this setup, we use:

```properties
listener.security.protocol.map=CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
```

> Later, you can replace `PLAINTEXT` with `SSL` or `SASL_*` for enhanced security.

---

### 📦 Topic Creation

```properties
auto.create.topics.enable=false
```

> Disables automatic topic creation. Set to `true` if you want Kafka to auto-create topics when they’re used.

---

### 📚 Internal Topic Replication

```properties
offsets.topic.replication.factor=3
```

* Ensures `__consumer_offsets` topic is replicated across all 3 nodes.
* Prevents data loss if a broker goes down.

---

## 🔁 Port Mapping

Each container maps external communication to a unique host port:

| Kafka Node | External Port | Purpose                 |
| ---------- | ------------- | ----------------------- |
| kafka-1    | 8081          | For producers/consumers |
| kafka-2    | 8082          | For producers/consumers |
| kafka-3    | 8083          | For producers/consumers |

> Change these ports if needed, just make sure the `advertised.listeners` match.

---

## 🧪 Example Summary for `kafka-1`

```properties
# Cluster Role
process.roles=broker,controller
node.id=1
cluster.id=YOUR-UNIQUE-CLUSTER-ID

# Listeners
listeners=INTERNAL://:9092,CONTROLLER://:9093,EXTERNAL://:8081
advertised.listeners=INTERNAL://kafka-1:9092,EXTERNAL://localhost:8081

# Mapping listener names to protocols
listener.security.protocol.map=CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT

# Define communication listener names
controller.listener.names=CONTROLLER
inter.broker.listener.name=INTERNAL

# Election
controller.quorum.voters=1@kafka-1:9093,2@kafka-2:9093,3@kafka-3:9093

# Internal topic replication
offsets.topic.replication.factor=3
```
---

# 🧪 Playing with Kafka Cluster (KRaft Mode) using Docker Compose

This section demonstrates how to interact with a multi-node Kafka cluster using Docker Compose, and observe **replication, leader election, and ISR (in-sync replicas)** in action.

---

## 📁 Prerequisites

1. Ensure you're in the directory that contains your Kafka cluster's `docker-compose.yml`.
2. If issues arise, **delete data directories** (`b1/`, `b2/`, `b3/`) to reset the state before retrying.

---

## 🚀 Start the Cluster

```bash
docker compose up -d
```

* This spins up **3 Kafka containers**:

    * `kafka-1`
    * `kafka-2`
    * `kafka-3`
* Wait for all services to start.

### ✅ Check Running Containers

```bash
docker ps
```

You should see all three Kafka containers up and running.

---

## 🛠️ Access Kafka Container

```bash
docker exec -it kafka-1 bash
```

> You can access any container, but we'll use `kafka-1` for this demo.

---

## 📦 Create a Topic

We'll create a topic named `order-events` with:

* 2 partitions
* Replication factor of 3

```bash
kafka-topics.sh \
  --create \
  --topic order-events \
  --partitions 2 \
  --replication-factor 3 \
  --bootstrap-server localhost:9092
```

---

## 📄 Describe the Topic

```bash
kafka-topics.sh \
  --describe \
  --topic order-events \
  --bootstrap-server localhost:9092
```

### 🧾 Sample Output

```
Topic: order-events  PartitionCount: 2  ReplicationFactor: 3
Partition: 0  Leader: 3  Replicas: 1,2,3  ISR: 1,2,3
Partition: 1  Leader: 1  Replicas: 1,2,3  ISR: 1,2,3
```

> * **Leader**: The broker currently handling write/read operations for that partition.
> * **Replicas**: All brokers storing a copy of the partition.
> * **ISR (In-Sync Replicas)**: Brokers with fully up-to-date data.

---

## 🔁 Leader Failover Test

### Step 1: Stop Kafka-3 (Leader of Partition 0)

```bash
docker stop kafka-3
```

Re-describe the topic:

```bash
kafka-topics.sh \
  --describe \
  --topic order-events \
  --bootstrap-server localhost:9092
```

### Result

* Kafka detects Kafka-3 is down
* **Leader re-election** occurs
* A new broker (e.g., Kafka-1) becomes the leader for Partition 0

```
Partition: 0  Leader: 1  Replicas: 1,2,3  ISR: 1,2
```

> Kafka-3 is no longer in the ISR.

---

### Step 2: Restart Kafka-3

```bash
docker start kafka-3
```

After some time, Kafka-3 re-joins the ISR:

```
ISR: 1,2,3
```

---

## 🧪 Additional Failover Scenarios

### Stop Kafka-2

```bash
docker stop kafka-2
```

Check ISR:

```
ISR: 1,3
```

---

### Stop Kafka-1 (from inside Kafka-1)

While in `kafka-1`, run:

```bash
docker stop kafka-1
```

> You'll be disconnected. Kafka-1 will stop, leaving only Kafka-3 running.

### Check from Kafka-3

```bash
docker exec -it kafka-3 bash
kafka-topics.sh --describe --topic order-events --bootstrap-server localhost:9092
```

Output:

```
Leader: 3  ISR: 3
```

> Only Kafka-3 is left and it has taken over leadership for all partitions.

---

## 🧠 Observations

* Kafka automatically **elects a new leader** when the current one fails.
* **ISR shrinks and expands** dynamically based on which brokers are online and fully synced.
* Kafka continues to function even when only **one broker** is available, though at reduced redundancy.

---

## 🧹 Cleanup (Optional)

To stop and remove all containers and volumes:

```bash
docker compose down -v
```

To clear log data manually:

```bash
rm -rf b1/ b2/ b3/
```

---

## ✅ Summary

| Action                      | Expected Outcome                                   |
| --------------------------- | -------------------------------------------------- |
| Stop leader broker          | Leader re-elected from remaining in-sync brokers   |
| Restart stopped broker      | It rejoins ISR once it catches up                  |
| All brokers stopped but one | Kafka continues to operate with limited redundancy |
| ISR shrinks/expands         | Reflects real-time sync status of brokers          |

---

# 🧪 Kafka Cluster Demo – Failover with Single Partition Topic

This demo shows how a **Kafka cluster handles failover** and maintains seamless data production and consumption, even when the **leader broker goes down**, using **a single partition with replication**.

---

## 🧹 Step 0: Clean Start

* Delete the existing topic.
* Create a new topic:

  * **Name**: `order-events`
  * **Partitions**: 1 (default)
  * **Replication Factor**: 3

```bash
kafka-topics.sh \
  --create \
  --topic order-events \
  --replication-factor 3 \
  --bootstrap-server localhost:9092
```

### 🎯 Why 1 Partition?

* Helps **observe message order** clearly.
* Ideal for testing **leader failover and ISR (in-sync replicas)**.
* Makes log inspection easier during producer/consumer activity.

---

## 🔍 Describe Topic

```bash
kafka-topics.sh \
  --describe \
  --topic order-events \
  --bootstrap-server localhost:9092
```

Example Output:

```
Topic: order-events  PartitionCount: 1  ReplicationFactor: 3
Partition: 0  Leader: 3  Replicas: 1,2,3  ISR: 1,2,3
```

> Broker **3** is initially the leader.

---

## 🛠️ Set Up Java Producer and Consumer

### 👷 Producer

* Sends messages every **50ms**.
* Uses broker on port **8081** as the **bootstrap server**.

### 🧑‍🏭 Consumer

* Subscribes to the `order-events` topic.
* Also uses **8081** as bootstrap server.
* Belongs to group: `demo-group`.

> Even with a **single bootstrap server**, Kafka automatically discovers the full cluster using **advertised listeners**.

---

## ✅ Start the Producer and Consumer

Start the consumer first:

```bash
# In IntelliJ or CLI
run ConsumerApp
```

Then start the producer:

```bash
run ProducerApp
```

### 🔎 Cluster Discovery

* Consumer uses **Kafka-1 (8081)** for bootstrapping.
* It receives metadata and connects to the **leader (Kafka-3, 8083)** to consume.
* Messages begin flowing between producer and consumer.

---

## 🧪 Simulate Failures

### 🔻 Stop Leader Node (Kafka-3)

```bash
docker stop kafka-3
```

* Kafka detects node-3 is down.
* New leader is elected (e.g., Kafka-1).
* ISR shrinks to `[1,2]`.

```bash
kafka-topics.sh --describe --topic order-events --bootstrap-server localhost:9092
```

Sample Output:

```
Leader: 1  Replicas: 1,2,3  ISR: 1,2
```

### ✅ Observation

* Messages still produced and consumed without data loss.
* Logs show a brief **disconnection warning**, but system remains operational.

---

### 🔻 Stop Bootstrap Node (Kafka-1)

```bash
docker stop kafka-1
```

* Kafka-1 is down, but producer/consumer **still work**.
* Cluster continues via **Kafka-2** and **Kafka-3**.
* Consumer already knows broker metadata; no interruption.

---

### 🔻 Stop Last Running Node (Kafka-2)

```bash
docker stop kafka-2
```

* Now all brokers are down.
* Producer/consumer stop functioning (as expected).
* Cluster is unavailable.

---

## 🔁 Bring Nodes Back Up

### Restart Kafka-1 and Kafka-3

```bash
docker start kafka-1
docker start kafka-3
```

### Check Topic Status Again

```bash
kafka-topics.sh --describe --topic order-events --bootstrap-server localhost:9092
```

Final Output:

```
Leader: 2  Replicas: 1,2,3  ISR: 1,2,3
```

✅ All nodes are back in sync.

---

## 🧠 Key Takeaways

| Scenario                         | Result                                 |
| -------------------------------- | -------------------------------------- |
| Leader node stopped              | Leader re-election happens seamlessly  |
| Bootstrap node stopped           | Cluster continues (metadata is cached) |
| Multiple nodes down, one remains | Still operational with reduced ISR     |
| All brokers down                 | Cluster becomes unavailable            |
| Brokers restarted                | All replicas sync and ISR restored     |

---

## 🧹 Cleanup (Optional)

```bash
docker compose down -v
rm -rf b1/ b2/ b3/
```

---
# ✅ Kafka Cluster Setup – Section Summary

## 🧱 Cluster Setup
- Deployed a **Kafka cluster** using **Docker Compose**.
- Spun up **3 Kafka broker containers**, each running as both broker and controller (via **KRaft mode**).
- Each broker had unique:
  - `node.id`
  - `server.properties`
  - Listener ports (`internal`, `external`, `controller`)

---

## 🧵 Topic Creation
- Created topic with:
  - Multiple **partitions** for scalability.
  - **Replication factor = 3** for fault tolerance.
- Kafka automatically:
  - **Elected partition leaders**
  - Assigned **followers** for replication

---

## 🛰️ Bootstrap Server Behavior
- Clients (producer/consumer) connect to **one bootstrap broker** (e.g., `localhost:8081`)
- Kafka returns **metadata**:
  - Which broker is leader for each partition
  - How to reach other brokers
- Clients use this info to route messages appropriately.
- Even if the **bootstrap server goes down**, clients continue to work via other brokers.

---

## 🔁 Broker Failover Demo
- **Stopped leader broker** → Kafka elected a new leader.
- **Producer/consumer continued** without manual reconnection.
- **Stopped 2 brokers** → cluster still worked with the 1 remaining broker (for read/write).
- **All 3 brokers synced** again when restarted.

---

## 🔍 Internal Kafka Communication Plan

```plaintext
                    Kafka Cluster Communication Types

     ┌────────────────────┐
     │   Controller Plane │ ← Controllers exchange metadata,

     ┌─────────────────┐
     │   Data Plane    │ ← Brokers replicate partitions, share logs.
     └─────────────────┘

     ┌────────────────────────────┐
     │ Client Communication Plane │ ← Producer/Consumer connects to
     └────────────────────────────┘     brokers to send/receive data.
````

---

## 📊 Kafka Cluster Diagram (3 Brokers with Replication)

```plaintext
                          Kafka Cluster

         +-------------+   +-------------+   +-------------+
         |  Kafka 1    |   |  Kafka 2    |   |  Kafka 3    |
         | (Node ID 1) |   | (Node ID 2) |   | (Node ID 3) |
         |-------------|   |-------------|   |-------------|
         | Partition 0 |←→→|  Replica    |   |  Replica    |
         |  Leader     |   | Partition 0 |   | Partition 0 |
         |-------------|   |-------------|   |-------------|
         | Replica     |   |  Leader     |←→→|  Replica    |
         | Partition 1 |   | Partition 1 |   | Partition 1 |
         +-------------+   +-------------+   +-------------+

     Clients → connect to bootstrap (e.g., Kafka 1) → redirected to leaders
```

---

## 🔑 Key Takeaways

* Kafka provides **horizontal scalability** and **high availability** using partitions and replication.
* Clients can connect to any broker (bootstrap), and Kafka handles redirection.
* **Failover is automatic** — new leaders are elected if a broker goes down.
* **Cluster metadata** is shared through internal topics and helps in client coordination.

---

## 📚 Optional References

* Kafka Docs – [https://kafka.apache.org/documentation/](https://kafka.apache.org/documentation/)
* KRaft Mode – [https://kafka.apache.org/documentation/#kraft](https://kafka.apache.org/documentation/#kraft)
* Kafka Docker Setup – [https://developer.confluent.io/quickstart/kafka-docker/](https://developer.confluent.io/quickstart/kafka-docker/)

---

