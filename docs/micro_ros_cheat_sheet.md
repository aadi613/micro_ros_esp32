# micro-ROS Cheat Sheet

> Quick-reference for the commands and API patterns used every day in this project.

---

## Daily Startup Commands

```bash
# 1. SSH into Pi
ssh aadi_1234@<PI_IP>

# 2. Enter ROS 2 container
sudo docker exec -it ros2_humble bash

# 3. Source ROS 2
source /opt/ros/humble/setup.bash

# 4. Start micro-ROS Agent
ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0

# ── In a NEW terminal ──

# 5. SSH into Pi again
ssh aadi_1234@<PI_IP>
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash

# 6. Check topics
ros2 topic list

# 7. View data
ros2 topic echo /encoder
```

---

## ROS 2 CLI Commands

### Topics
```bash
ros2 topic list                          # List all active topics
ros2 topic echo /topic_name             # Print messages live
ros2 topic echo /topic_name --once      # Print one message then exit
ros2 topic hz /topic_name               # Measure publish rate
ros2 topic info /topic_name             # Type, pub count, sub count
ros2 topic bw /topic_name               # Bandwidth usage

# Publish once
ros2 topic pub --once /topic std_msgs/msg/Int32 "{data: 42}"

# Publish at 1 Hz
ros2 topic pub /topic std_msgs/msg/Int32 "{data: 42}" --rate 1

# Publish Twist (for cmd_vel)
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 0.5, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.0}}"
```

### Nodes
```bash
ros2 node list                           # List all active nodes
ros2 node info /node_name               # Node's topics, services, params
```

### Services & Parameters
```bash
ros2 service list                        # List all services
ros2 param list /node_name              # List node parameters
ros2 param get /node_name param_name    # Read a parameter
ros2 param set /node_name param_name 42 # Set a parameter
```

---

## Docker Commands

```bash
# List running containers
sudo docker ps

# List all containers (including stopped)
sudo docker ps -a

# Start a stopped container
sudo docker start ros2_humble

# Enter a running container
sudo docker exec -it ros2_humble bash

# Stop a container
sudo docker stop ros2_humble

# Auto-restart container on boot
sudo docker update --restart unless-stopped ros2_humble

# View container logs
sudo docker logs ros2_humble

# Remove and recreate container
sudo docker rm ros2_humble
sudo docker run -it \
  --name ros2_humble \
  --network host \
  --privileged \
  -v /dev:/dev \
  ros:humble bash
```

---

## ESP32 / ESP-IDF Commands

```bash
# Source ESP-IDF (run once per terminal)
. $HOME/esp/esp-idf/export.sh

# Set target chip
idf.py set-target esp32

# Build project
idf.py build

# Flash firmware (replace /dev/ttyUSB0 with your port)
idf.py -p /dev/ttyUSB0 flash

# Open serial monitor (Ctrl+] to exit)
idf.py -p /dev/ttyUSB0 monitor

# Build + flash + monitor in one command
idf.py -p /dev/ttyUSB0 flash monitor

# Flash with slower baud (if failing)
idf.py -p /dev/ttyUSB0 -b 115200 flash

# Clean build artifacts
idf.py fullclean
```

---

## Serial Port Commands

```bash
# Find ESP32 port
ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null

# Monitor with minicom
minicom -D /dev/ttyUSB0 -b 115200

# Monitor with screen
screen /dev/ttyUSB0 115200

# View recent USB events
sudo dmesg | tail -20 | grep -i usb

# Fix permissions
sudo usermod -aG dialout $USER
sudo chmod 666 /dev/ttyUSB0
```

---

## micro-ROS C API Quick Reference

### Initialization
```c
rcl_allocator_t allocator = rcl_get_default_allocator();
rclc_support_t support;
rclc_support_init(&support, 0, NULL, &allocator);

rcl_node_t node;
rclc_node_init_default(&node, "node_name", "", &support);
```

### Publisher
```c
rcl_publisher_t publisher;
std_msgs__msg__Int32 msg;

rclc_publisher_init_default(
    &publisher, &node,
    ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, Int32),
    "topic_name");

// Publish
msg.data = 42;
rcl_publish(&publisher, &msg, NULL);
```

### Subscriber
```c
rcl_subscription_t subscriber;
std_msgs__msg__Int32 msg;

rclc_subscription_init_default(
    &subscriber, &node,
    ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, Int32),
    "topic_name");

void callback(const void * msgin) {
    const std_msgs__msg__Int32 * m = (const std_msgs__msg__Int32 *)msgin;
    printf("Got: %d\n", m->data);
}
```

### Timer
```c
rcl_timer_t timer;
rclc_timer_init_default(&timer, &support,
    RCL_MS_TO_NS(1000),   // 1000 ms = 1 Hz
    timer_callback);

void timer_callback(rcl_timer_t * timer, int64_t last_call_time) {
    RCLC_UNUSED(last_call_time);
    if (timer != NULL) {
        // publish or do work
    }
}
```

### Executor
```c
// n_handles = total timers + subscribers you will add
rclc_executor_t executor;
rclc_executor_init(&executor, &support.context, 2, &allocator);

rclc_executor_add_timer(&executor, &timer);
rclc_executor_add_subscription(&executor, &subscriber, &msg,
    &callback, ON_NEW_DATA);

// Spin (non-blocking, call in a loop)
while (1) {
    rclc_executor_spin_some(&executor, RCL_MS_TO_NS(100));
    usleep(100000);
}
```

### Error Macros
```c
#define RCCHECK(fn) { \
    rcl_ret_t temp_rc = fn; \
    if((temp_rc != RCL_RET_OK)) { \
        printf("Error %d line %d\n", (int)temp_rc, __LINE__); \
        vTaskDelete(NULL); \
    } \
}

#define RCSOFTCHECK(fn) { \
    rcl_ret_t temp_rc = fn; \
    if((temp_rc != RCL_RET_OK)) { \
        printf("Soft error %d line %d\n", (int)temp_rc, __LINE__); \
    } \
}
```

---

## Common Message Types

```bash
# Int32
std_msgs/msg/Int32
  "{data: 42}"

# Bool
std_msgs/msg/Bool
  "{data: true}"
  "{data: false}"

# Float32
std_msgs/msg/Float32
  "{data: 3.14}"

# String
std_msgs/msg/String
  "{data: 'hello'}"

# Twist (velocity command)
geometry_msgs/msg/Twist
  "{linear: {x: 0.5, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.0}}"

# IMU
sensor_msgs/msg/Imu
  # (published from ESP32, not usually typed by hand)
```

---

## ESP32 LEDC (PWM) Quick Reference

```c
// Timer config
ledc_timer_config_t t = {
    .speed_mode      = LEDC_HIGH_SPEED_MODE,
    .timer_num       = LEDC_TIMER_0,
    .duty_resolution = LEDC_TIMER_8_BIT,   // 0–255
    .freq_hz         = 5000,
    .clk_cfg         = LEDC_AUTO_CLK
};
ledc_timer_config(&t);

// Channel config
ledc_channel_config_t c = {
    .gpio_num   = 2,                        // LED pin
    .speed_mode = LEDC_HIGH_SPEED_MODE,
    .channel    = LEDC_CHANNEL_0,
    .timer_sel  = LEDC_TIMER_0,
    .duty       = 0,
    .hpoint     = 0
};
ledc_channel_config(&c);

// Set brightness (0–255)
ledc_set_duty(LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0, 128);
ledc_update_duty(LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0);
```

---

## Scripts Reference

```bash
cd ~/micro_ros_esp32/scripts

./01_check_esp32.sh              # Detect ESP32 USB port
./02_start_agent.sh              # Start micro-ROS Agent
./02_start_agent.sh /dev/ttyACM0 # Use different port
./03_verify_topics.sh            # Check all topics
./04_view_data.sh                # Echo /encoder
./04_view_data.sh /imu           # Echo /imu
./05_publish_command.sh          # Publish to /motor_cmd
./06_test_led.sh blink           # Blink LED 5 times
./06_test_led.sh on              # LED ON
./06_test_led.sh off             # LED OFF
./07_verify_nodes.sh             # Check nodes
./08_validate_all.sh             # Full validation
./daily_workflow.sh              # Interactive guide
```
