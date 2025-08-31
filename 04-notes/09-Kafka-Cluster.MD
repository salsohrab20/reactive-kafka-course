# Kafka Cluster Setup with KRaft Mode

## Overview

In this section, we will set up a **Kafka cluster using KRaft mode** and explore its **high availability** and **horizontal scalability**. Along the way, we’ll deepen our understanding of key Kafka concepts such as **replication** and **controller election**.

---

## Cluster Setup Concepts

### Node Roles

Kafka servers (nodes) can be assigned different roles when started:

* **Broker**: Handles read/write operations from producers/consumers.
* **Controller**: Manages partition leaders, ISR (in-sync replicas), and cluster metadata.
* **Broker + Controller**: A node can serve both roles simultaneously.

> Although multiple nodes can have the controller role, **only one becomes the active controller** through a leader election process.

---

## Creating a Topic

As a developer, when creating a topic:

* A **topic** is essentially a collection of **partitions**.
* To improve performance and scalability, create topics with **multiple partitions**.

### Example

Creating a topic `order-events` with 2 partitions:

* The controller assigns leadership for each partition:

    * Node A → Leader for Partition 0
    * Node B → Leader for Partition 1

---

## Replication & High Availability

To ensure fault tolerance:

* Specify a **replication factor** when creating the topic.
* For example, `replication.factor = 3` ensures:

    * 1 **leader** + 2 **followers** for each partition.

### Partition Replication Example

For a topic with 2 partitions and replication factor 3:

* **Partition 0**

    * Leader: Node A
    * Followers: Node B, Node C
* **Partition 1**

    * Leader: Node B
    * Followers: Node A, Node C

> Writes to the leader are **replicated** to followers in real-time for durability.

---

## Cluster Metadata Synchronization

Kafka uses an **internal topic** called `__cluster_metadata` to share cluster information:

* The **controller publishes metadata** (e.g., partition leaders/followers) to this topic.
* **All brokers subscribe** to it, even if they host no partitions or replicas.

### Why This Matters

* Even a broker with no partition/replica still knows the full cluster state.
* When an application connects via a **bootstrap server** (even a passive node), the node can provide metadata about:

    * All topics
    * Partition leaders/followers
    * Broker roles

---

## Summary

* Kafka in KRaft mode simplifies setup by removing dependency on ZooKeeper.
* The system is highly available through replication.
* Cluster metadata is efficiently shared via internal topics.
* Any broker can serve as a bootstrap node for clients due to shared metadata knowledge.

---

# Kafka Cluster Communication Overview

In a Kafka cluster, there are **three distinct types of communication** that occur, each serving a specific purpose:

---

## 1. **Control Plane Communication**

* **Participants**: Controllers (Kafka nodes with controller role).
* **Purpose**: Coordination, leader election, cluster metadata updates.
* **Scope**: Internal to the cluster.
* **Example**: Electing the active controller, publishing partition assignments.

---

## 2. **Data Plane Communication**

* **Participants**: Brokers communicating with each other.
* **Purpose**: Data replication, partition synchronization.
* **Scope**: Internal to the cluster (within subnet).
* **Example**: Replicating partition data from leader to followers.

---

## 3. **Client Communication**

* **Participants**: External applications (producers/consumers) interacting with brokers.
* **Purpose**: Producing data to, or consuming data from, Kafka topics.
* **Scope**: External access to the cluster.
* **Example**: A producer sending order events to a Kafka topic.

---

## Summary of Communication Types

| Type                 | Participants                  | Purpose                     | Scope    |
| -------------------- | ----------------------------- | --------------------------- | -------- |
| Control Plane        | Controllers                   | Cluster coordination        | Internal |
| Data Plane           | Brokers                       | Data replication            | Internal |
| Client Communication | Producers/Consumers & Brokers | Data production/consumption | External |

---

## Kafka Listeners

A **Kafka server can listen on multiple ports**, each dedicated to a specific type of communication. These ports are configured using **Kafka listeners**.

### Example Listener Setup

* `PLAINTEXT://broker-1.internal:9092` → Internal communication (Control + Data plane)
* `EXTERNAL://broker-1.example.com:29092` → External communication (Client access)

> Kafka identifies these listeners via configuration, typically using:

```properties
listeners=PLAINTEXT://:9092,EXTERNAL://:29092
advertised.listeners=PLAINTEXT://broker-1.internal:9092,EXTERNAL://broker-1.example.com:29092
```

---

## Why Separate Listeners?

* **Security**: Internal-only communication is kept within a secure subnet.
* **Clarity**: Explicitly separates internal cluster traffic from external client traffic.
* **Scalability**: Helps scale internal vs. external traffic independently.

---

## Understanding with Docker Compose

If this seems abstract, don’t worry. In the next step, we’ll **set up a Kafka cluster using Docker Compose**, where we’ll see:

* How listeners are configured.
* How each service communicates.
* How clients (e.g., Kafka CLI or apps) interact with the brokers.

This hands-on approach will make these concepts much clearer.

---
