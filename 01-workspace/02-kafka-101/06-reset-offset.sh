# stop the consumers before you enter this command

# dry-run  -- provides last 3 messages
 kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --group cg \
    --topic hello-world \
    --reset-offsets \
    --shift-by -3 \
    --dry-run 

# reset offset by shifting the offset -- provides last 3 messages
 kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --group cg \
    --topic hello-world \
    --reset-offsets \
    --shift-by -3 \
    --execute   

# reset by duration  -- provides messages received in 5 minutes
kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --topic hello-world \
    --group cg \
    --reset-offsets \
    --by-duration PT5M \
    --execute

# -- to the beginning -- provides messages received from beginning
kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --topic hello-world \
    --group cg \
    --reset-offsets \
    --to-earliest \
    --execute

# -- to the end -- provides latest messages received
kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --topic hello-world \
    --group cg \
    --reset-offsets \
    --to-latest \
    --execute   

# -- to date-time -- provides messages received from the specific dates
kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --topic hello-world \
    --group cg \
    --reset-offsets \
    --to-datetime 2023-01-01T01:00:00.000 \
    --execute            