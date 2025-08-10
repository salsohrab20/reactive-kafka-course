package com.vinsguru.reactivekafkaplayground.sec01;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import reactor.kafka.receiver.KafkaReceiver;
import reactor.kafka.receiver.ReceiverOptions;

import java.util.List;
import java.util.Map;

/*
  goal: to demo a simple kafka consumer using reactor kafka
  producer ----> kafka broker <----------> consumer

  topic: order-events
  partitions: 1
  log-end-offset: 15
  current-offset: 15

 */
public class Lec01KafkaConsumer {

    private static final Logger log = LoggerFactory.getLogger(Lec01KafkaConsumer.class);

    public static void main(String[] args) {

        Map<String, Object> serversConfig = Map.<String, Object>of(
                ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092",
                ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class,
                ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class,
                ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest",
                ConsumerConfig.GROUP_INSTANCE_ID_CONFIG, "1",
                ConsumerConfig.GROUP_ID_CONFIG, "demo-group-123"
        );

        var options = ReceiverOptions.create(serversConfig).subscription(List.of("order-events"));

        KafkaReceiver.create(options)
                .receive()
                .doOnNext(r -> log.info("key : {} and value :{}", r.key(), r.value() ))
                .doOnNext(r -> r.receiverOffset().acknowledge())
                .subscribe();
    }

}
