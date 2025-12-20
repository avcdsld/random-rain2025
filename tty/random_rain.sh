while true
do
    python3 gen_rain1.py
    python3 befunge93.py < wandering_rain.bf
    sleep 30s
    python3 gen_rain2.py
    python3 befunge93.py < straight_rain.bf
    sleep 30s
done
