# ESP32 Publisher

> ESP32 publishes an incrementing `Int32` counter to ROS 2 at **1 Hz** using micro-ROS over USB serial.

---

## What This Module Does

The ESP32 runs as a **micro-ROS publisher node**. It:

1. Initializes a micro-ROS node called `esp32_publisher_node`
2. Creates a publisher on topic `/esp32_publisher` with message type `std_msgs/Int32`
3. Sets up a **1-second timer** using `rclc_timer`
4. On every timer tick, **increments** a counter and **publishes** it to ROS 2

```
ESP32                                    Raspberry Pi (ROS 2)
─────                                    ────────────────────
[FreeRTOS Task]
    │
    ├── rclc_support_init()              micro-ROS Agent (serial)
    ├── rclc_node_init()                     │
    ├── rclc_publisher_init()                │ USB Serial
    ├── rclc_timer_init()  (1 Hz)            │
    ├── rclc_executor_spin()    ────────────►│──► /esp32_publisher (Int32)
    └── msg.data++ each tick
```

---

## Source Code: `app.c`

```c
#include <stdio.h>
#include <unistd.h>

#include <rcl/rcl.h>
#include <rcl/error_handling.h>
#include <std_msgs/msg/int32.h>

#include <rclc/rclc.h>
#include <rclc/executor.h>

#ifdef ESP_PLATFORM
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#endif

// Abort on error
#define RCCHECK(fn) { \
    rcl_ret_t temp_rc = fn; \
    if((temp_rc != RCL_RET_OK)) { \
        printf("Failed status on line %d: %d. Aborting.\n", \
               __LINE__, (int)temp_rc); \
        vTaskDelete(NULL); \
    } \
}

// Log but continue on soft error
#define RCSOFTCHECK(fn) { \
    rcl_ret_t temp_rc = fn; \
    if((temp_rc != RCL_RET_OK)) { \
        printf("Failed status on line %d: %d. Continuing.\n", \
               __LINE__, (int)temp_rc); \
    } \
}

rcl_publisher_t publisher;
std_msgs__msg__Int32 msg;

// Called every 1 second by the executor
void timer_callback(rcl_timer_t * timer, int64_t last_call_time)
{
    RCLC_UNUSED(last_call_time);
    if (timer != NULL) {
        RCSOFTCHECK(rcl_publish(&publisher, &msg, NULL));
        msg.data++;   // Increment counter
    }
}

void micro_ros_task(void * arg)
{
    rcl_allocator_t allocator = rcl_get_default_allocator();
    rclc_support_t support;

    // Initialize micro-ROS (connects to Agent over serial)
    RCCHECK(rclc_support_init(&support, 0, NULL, &allocator));

    // Create node
    rcl_node_t node;
    RCCHECK(rclc_node_init_default(&node, "esp32_publisher_node", "", &support));

    // Create publisher
    RCCHECK(rclc_publisher_init_default(
        &publisher,
        &node,
        ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, Int32),
        "esp32_publisher"));

    // Create 1-second timer
    rcl_timer_t timer;
    const unsigned int timer_timeout = 1000;  // ms
    RCCHECK(rclc_timer_init_default(&timer, &support,
        RCL_MS_TO_NS(timer_timeout), timer_callback));

    // Create executor and spin
    rclc_executor_t executor;
    RCCHECK(rclc_executor_init(&executor, &support.context, 1, &allocator));
    RCCHECK(rclc_executor_add_timer(&executor, &timer));

    msg.data = 0;

    while (1) {
        rclc_executor_spin_some(&executor, RCL_MS_TO_NS(100));
        usleep(100000);  // 100 ms sleep
    }
}

void app_main(void)
{
    xTaskCreate(micro_ros_task, "micro_ros_task", 16000, NULL, 5, NULL);
}
```

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| `rclc_support_init()` | Initializes the micro-ROS DDS transport layer |
| `rclc_node_init_default()` | Creates a named ROS 2 node on the ESP32 |
| `rclc_publisher_init_default()` | Creates a reliable QoS publisher |
| `rclc_timer_init_default()` | Creates a periodic callback timer |
| `rclc_executor_spin_some()` | Non-blocking executor tick (processes callbacks) |
| `msg.data++` | Increments the published Int32 each second |

---

## Build & Flash

```bash
# Navigate to your ESP-IDF project root containing this app.c
cd ~/esp/micro_ros_project

# Copy app.c to main/
cp path/to/ESP32_Publisher/app.c main/app.c

# Source ESP-IDF
. $HOME/esp/esp-idf/export.sh

# Build
idf.py build

# Flash (ESP32 connected to laptop via USB)
idf.py -p /dev/ttyUSB0 flash

# Monitor serial output
idf.py -p /dev/ttyUSB0 monitor
```

---

## Verify on ROS 2 Side

**Start the micro-ROS Agent on the Raspberry Pi:**

```bash
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash
ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0
```

**In a second terminal on the Pi:**

```bash
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash

# Check the topic exists
ros2 topic list
# Expected: /esp32_publisher

# View the live counter
ros2 topic echo /esp32_publisher
# Expected:
# data: 0
# ---
# data: 1
# ---
# data: 2

# Check publish rate
ros2 topic hz /esp32_publisher
# Expected: average rate: 1.000
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Topic not visible | Is the Agent running? Is ESP32 connected? |
| Data stuck at `0` | Check timer callback — `msg.data++` must be inside it |
| `Failed status on line X` in monitor | Agent not running — start it first |
| Build fails on `rclc` headers | Check `micro_ros_espidf_component` is in `components/` |

---

## What's Next

→ [ESP32 Subscriber](../ESP32_Subscriber/README.md) — Make the ESP32 **receive** commands from ROS 2.
