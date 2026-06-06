# micro-ROS ESP32

> Step-by-step terminal commands to run Publisher, Subscriber, and PWM LED Control on ESP32 with ROS 2 Humble via Raspberry Pi.

---

## Prerequisites (already done)
- ROS 2 Humble running inside Docker on Raspberry Pi (`ros2_humble` container)
- micro-ROS Agent installed inside the container
- micro-ROS firmware flashed on ESP32
- ESP32 connected to Raspberry Pi via USB

---

## Step 1 — Find the ESP32 Port (on Raspberry Pi)

```bash
ls /dev/ttyUSB*
```
Expected: `/dev/ttyUSB0`

---

## Step 2 — Enter Docker Container

```bash
sudo docker exec -it ros2_humble bash
```

```bash
source /opt/ros/humble/setup.bash
```

---

## Step 3 — Start micro-ROS Agent

```bash
ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0
```

> Keep this terminal open.

---

## Step 4 — Open a Second Terminal (new SSH session into Pi)

```bash
sudo docker exec -it ros2_humble bash
```

```bash
source /opt/ros/humble/setup.bash
```

---

## Publisher — ESP32 sends Int32 counter to ROS 2

Flash `ESP32_Publisher/app.c` to the ESP32, then verify:

```bash
ros2 topic list
```

```bash
ros2 topic echo /esp32_publisher
```

Expected output:
```
data: 0
---
data: 1
---
data: 2
```

---

## Subscriber — ROS 2 sends Int32 to ESP32

Flash `ESP32_Subscriber/app.c` to the ESP32, then send a value:

```bash
ros2 topic pub --once /esp32_subscriber std_msgs/msg/Int32 "{data: 42}"
```

Check ESP32 serial monitor — it will print: `Received: 42`

---

## PWM LED Control — Control inbuilt LED brightness from ROS 2

Flash `PWM_LED_Control/app.c` to the ESP32 (LED is on GPIO 2).

Turn LED **full brightness**:
```bash
ros2 topic pub --once /led_brightness std_msgs/msg/Int32 "{data: 255}"
```

Turn LED **half brightness**:
```bash
ros2 topic pub --once /led_brightness std_msgs/msg/Int32 "{data: 128}"
```

Turn LED **off**:
```bash
ros2 topic pub --once /led_brightness std_msgs/msg/Int32 "{data: 0}"
```

---

## Check Active Nodes and Topics

```bash
ros2 node list
```

```bash
ros2 topic list
```

```bash
ros2 topic hz /esp32_publisher
```
