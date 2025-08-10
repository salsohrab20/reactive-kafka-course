# Lecture 02: Consuming from Multiple Kafka Topics

In this lecture, we explore how a Kafka consumer can subscribe to **multiple topics**.

---

## Why Consume from Multiple Topics?

Imagine an **Inventory Service** that needs to respond to different types of events:

- **Order Events** (e.g., purchases)
- **Order Return Events** (e.g., returns/refunds)

These events may be published to **separate topics**:
- `order-events`
- `order-returns`

To handle both, the consumer application can subscribe to multiple topics.

---

## How to Subscribe to Multiple Topics

Kafka consumers can be configured in two ways:


### 1.Using a Regular Expression
- Kafka also allows topic subscription using regex patterns:

```java
Pattern pattern = Pattern.compile("order-.*");
consumer.subscribe(pattern);
```

> This will match any topic starting with "order-", like:
- order-events
- order-returns 
- order-updates, etc.

#### Send sample events:

# In order-events producer
- order1
- order2

# In order-returns producer
- return1
- return2


#### Result
##### The consumer successfully receives and logs messages from both topics:
```
Topic: order-events, Value: order1
Topic: order-events, Value: order2
Topic: order-returns, Value: return1
Topic: order-returns, Value: return2
```

