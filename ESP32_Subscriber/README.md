# ESP32 Subscriber

> ESP32 **receives** `Int32` messages from ROS 2 and processes them in a callback — the foundation for all command-and-control from the Pi to the robot.

---

## What This Module Does

The ESP32 runs as a **micro-ROS subscriber node**. It:

1. Initializes a micro-ROS node called `esp32_subscriber_node`
2. Creates a subscriber on topic `/esp32_subscriber` with type `std_msgs/Int32`
3. Registers a **callback function** triggered on every received message
4. The callback prints the received value to the serial monitor

```
Raspberry Pi (ROS 2)                    ESP32
────────────────────                    ─────
ros2 topic pub /esp32_subscriber        [FreeRTOS Task]
  std_msgs/msg/Int32 "{data: 42}"           │
    │                                        ├── rclc_support_init()
    │ USB Serial                             ├── rclc_node_init()
    │ (micro-ROS Agent)                      ├── rclc_subscription_init()
    └─────────────────────────────────────►  ├── rclc_executor_spin()
                                             └── subscription_callback()
                                                     └── printf("Received: 42")
```

---

## Source Code: `app.c`

```c
#include <rcl/rcl.h>
#include <rcl/error_handling.h>
#include <rclc/rclc.h>
#include <rclc/executor.h>

#include <std_msgs/msg/int32.h>

#include <stdio.h>
#ifdef ESP_PLATFORM
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#endif
#include <unistd.h>

#define RCCHECK(fn) { \
    rcl_ret_t temp_rc = fn; \
    if((temp_rc != RCL_RET_OK)) { \
        printf("Failed status on line %d: %d. Aborting.\n", \
               __LINE__, (int)temp_rc); \
        vTaskDelete(NULL); \
    } \
}

#define RCSOFTCHECK(fn) { \
    rcl_ret_t temp_rc = fn; \
    if((temp_rc != RCL_RET_OK)) { \
        printf("Failed status on line %d: %d. Continuing.\n", \
               __LINE__, (int)temp_rc); \
    } \
}

rcl_subscription_t subscriber;
std_msgs__msg__Int32 msg;

// Called by the executor when a new message arrives
void subscription_callback(const void * msgin)
{
    const std_msgs__msg__Int32 * msg = (const std_msgs__msg__Int32 *)msgin;
    printf("Received: %d\n", (int)msg->data);
}

void micro_ros_task(void * arg)
{
    rcl_allocator_t allocator = rcl_get_default_allocator();
    rclc_support_t support;

    RCCHECK(rclc_support_init(&support, 0, NULL, &allocator));

    rcl_node_t node;
    RCCHECK(rclc_node_init_default(&node, "esp32_subscriber_node", "", &support));

    RCCHECK(rclc_subscription_init_default(
        &subscriber,
        &node,
        ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, Int32),
        "esp32_subscriber"));

    rclc_executor_t executor;
    RCCHECK(rclc_executor_init(&executor, &support.context, 1, &allocator));
    RCCHECK(rclc_executor_add_subscription(
        &executor, &subscriber, &msg, &subscription_callback, ON_NEW_DATA));

    while (1) {
        rclc_executor_spin_some(&executor, RCL_MS_TO_NS(100));
        usleep(100000);
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
| `rclc_subscription_init_default()` | Creates a reliable QoS subscriber |
| `subscription_callback()` | Triggered by executor on each new message |
| `rclc_executor_add_subscription()` | Registers callback with the executor |
| `ON_NEW_DATA` | Executor mode: only run callback when new data arrives |
| `(std_msgs__msg__Int32 *)msgin` | Cast the generic `void*` to the correct message type |

---

## Build & Flash

```bash
# Copy app.c to your ESP-IDF project
cp path/to/ESP32_Subscriber/app.c main/app.c

# Source ESP-IDF
. $HOME/esp/esp-idf/export.sh

# Build, flash, and monitor
idf.py build
idf.py -p /dev/ttyUSB0 flash
idf.py -p /dev/ttyUSB0 monitor
```

Leave the monitor open — you will see incoming messages printed here.

---

## Test on ROS 2 Side

**Start the Agent on Pi (Terminal 1):**

```bash
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash
ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0
```

**Send a message to ESP32 (Terminal 2):**

```bash
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash

# Send value 42 once
ros2 topic pub --once /esp32_subscriber std_msgs/msg/Int32 "{data: 42}"

# Send value 100 repeatedly (1 Hz)
ros2 topic pub /esp32_subscriber std_msgs/msg/Int32 "{data: 100}" --rate 1
```

**ESP32 serial monitor (idf.py monitor) should show:**

```
Received: 42
Received: 100
Received: 100
Received: 100
```

**Verify from ROS 2:**

```bash
ros2 node list
# /esp32_subscriber_node

ros2 topic list
# /esp32_subscriber
```

---

## Extending the Callback

The callback is where you add your robot's logic. Examples:

```c
void subscription_callback(const void * msgin)
{
    const std_msgs__msg__Int32 * msg = (const std_msgs__msg__Int32 *)msgin;
    int value = (int)msg->data;

    // Example: control motor speed
    set_motor_speed(value);

    // Example: set PWM duty cycle
    ledc_set_duty(LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0, value);
    ledc_update_duty(LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0);

    // Example: toggle GPIO
    gpio_set_level(GPIO_NUM_2, value > 0 ? 1 : 0);
}
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Callback never fires | Check topic name matches exactly (case sensitive) |
| Node not listed | Make sure Agent is running before powering ESP32 |
| `Failed status` in monitor | Agent not connected — start it first |
| Serial monitor shows garbage | Baud rate mismatch — use `115200` |

---

## What's Next

→ [ROS2 to ESP32 Communication](../ROS2_to_ESP32_Communication/README.md) — Combine publisher + subscriber for **bidirectional** communication.
