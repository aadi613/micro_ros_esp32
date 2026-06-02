# ROS 2 ↔ ESP32 Communication

> Bidirectional communication between ROS 2 (on Raspberry Pi) and ESP32 — the ESP32 simultaneously **publishes** sensor data and **subscribes** to control commands.

---

## What This Module Covers

This module combines the publisher and subscriber into a single firmware, enabling full two-way communication:

```
Raspberry Pi (ROS 2)                      ESP32
────────────────────                      ─────
                                          ┌─────────────────────┐
ros2 topic echo /sensor_data  ◄──────────│ Publisher (1 Hz)     │
                                          │  msg.data++ counter  │
                                          │                      │
ros2 topic pub /cmd_vel ──────────────►  │ Subscriber           │
  Twist "{linear: {x: 0.5}}"             │  callback executes   │
                                          └─────────────────────┘
```

This is the **core pattern** for any ROS 2 robot:
- ESP32 sends sensor readings **up** to the Pi
- Pi sends velocity/control commands **down** to the ESP32

---

## Architecture

```
micro_ros_task (FreeRTOS)
│
├── rclc_support_init()         ← Connect to Agent
├── rclc_node_init()            ← Create node: "esp32_node"
│
├── rclc_publisher_init()       ← Publisher on /sensor_data
├── rclc_subscription_init()    ← Subscriber on /cmd_vel
├── rclc_timer_init() (1 Hz)    ← Triggers publish
│
├── rclc_executor_init()
│     ├── add_timer()           ← Timer → publish callback
│     └── add_subscription()    ← /cmd_vel → control callback
│
└── rclc_executor_spin()        ← Infinite loop, handles both
```

---

## Firmware Pattern (Combined Pub + Sub)

```c
#include <rcl/rcl.h>
#include <rcl/error_handling.h>
#include <rclc/rclc.h>
#include <rclc/executor.h>
#include <std_msgs/msg/int32.h>
#include <geometry_msgs/msg/twist.h>

#include <stdio.h>
#ifdef ESP_PLATFORM
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#endif
#include <unistd.h>

#define RCCHECK(fn)     { rcl_ret_t temp_rc = fn; \
    if((temp_rc != RCL_RET_OK)){printf("Error %d line %d\n",(int)temp_rc,__LINE__);vTaskDelete(NULL);}}
#define RCSOFTCHECK(fn) { rcl_ret_t temp_rc = fn; \
    if((temp_rc != RCL_RET_OK)){printf("Soft error %d line %d\n",(int)temp_rc,__LINE__);}}

rcl_publisher_t    publisher;
rcl_subscription_t subscriber;
std_msgs__msg__Int32          sensor_msg;
geometry_msgs__msg__Twist     cmd_msg;

// ── Publish callback (called every 1 second) ──────────────────────────────
void timer_callback(rcl_timer_t * timer, int64_t last_call_time)
{
    RCLC_UNUSED(last_call_time);
    if (timer != NULL) {
        RCSOFTCHECK(rcl_publish(&publisher, &sensor_msg, NULL));
        printf("Published sensor: %d\n", (int)sensor_msg.data);
        sensor_msg.data++;
    }
}

// ── Subscribe callback (called on each received /cmd_vel) ─────────────────
void cmd_callback(const void * msgin)
{
    const geometry_msgs__msg__Twist * msg =
        (const geometry_msgs__msg__Twist *)msgin;

    float linear_x  = (float)msg->linear.x;
    float angular_z = (float)msg->angular.z;

    printf("CMD: linear=%.2f  angular=%.2f\n", linear_x, angular_z);

    // TODO: translate to motor PWM values
    // int left_speed  = (int)((linear_x - angular_z) * 255);
    // int right_speed = (int)((linear_x + angular_z) * 255);
    // set_motor(left_speed, right_speed);
}

void micro_ros_task(void * arg)
{
    rcl_allocator_t allocator = rcl_get_default_allocator();
    rclc_support_t  support;

    RCCHECK(rclc_support_init(&support, 0, NULL, &allocator));

    rcl_node_t node;
    RCCHECK(rclc_node_init_default(&node, "esp32_node", "", &support));

    // Publisher: /sensor_data  (Int32)
    RCCHECK(rclc_publisher_init_default(
        &publisher, &node,
        ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, Int32),
        "sensor_data"));

    // Subscriber: /cmd_vel  (Twist)
    RCCHECK(rclc_subscription_init_default(
        &subscriber, &node,
        ROSIDL_GET_MSG_TYPE_SUPPORT(geometry_msgs, msg, Twist),
        "cmd_vel"));

    // 1-second timer
    rcl_timer_t timer;
    RCCHECK(rclc_timer_init_default(&timer, &support,
        RCL_MS_TO_NS(1000), timer_callback));

    // Executor: 2 handles (1 timer + 1 subscription)
    rclc_executor_t executor;
    RCCHECK(rclc_executor_init(&executor, &support.context, 2, &allocator));
    RCCHECK(rclc_executor_add_timer(&executor, &timer));
    RCCHECK(rclc_executor_add_subscription(
        &executor, &subscriber, &cmd_msg, &cmd_callback, ON_NEW_DATA));

    sensor_msg.data = 0;

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

> **Key point:** The executor `init` count must match the number of handles added (`2` here = 1 timer + 1 subscriber).

---

## Testing Bidirectional Communication

### Terminal 1 — Start Agent
```bash
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash
ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/ttyUSB0
```

### Terminal 2 — Watch incoming sensor data
```bash
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash
ros2 topic echo /sensor_data
```

Expected:
```
data: 0
---
data: 1
---
data: 2
```

### Terminal 3 — Send velocity command to ESP32
```bash
sudo docker exec -it ros2_humble bash
source /opt/ros/humble/setup.bash

# Move forward at speed 0.5
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 0.5, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"

# Turn left
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 0.0}, angular: {z: 0.5}}"

# Stop
ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 0.0}, angular: {z: 0.0}}"
```

**ESP32 serial monitor should show:**
```
Published sensor: 12
CMD: linear=0.50  angular=0.00
Published sensor: 13
CMD: linear=0.00  angular=0.50
```

---

## Verify Nodes and Topics

```bash
ros2 node list
# /esp32_node
# /micro_ros_agent

ros2 topic list
# /sensor_data
# /cmd_vel
# /parameter_events
# /rosout

ros2 topic info /sensor_data
# Type: std_msgs/msg/Int32
# Publisher count: 1
# Subscription count: 0

ros2 topic info /cmd_vel
# Type: geometry_msgs/msg/Twist
# Publisher count: 0
# Subscription count: 1
```

---

## Executor Handle Count — Common Mistake

The executor `n_handles` parameter **must equal** the total number of callbacks added:

```c
// Wrong: will crash if handles > n_handles
rclc_executor_init(&executor, &support.context, 1, &allocator);
rclc_executor_add_timer(&executor, &timer);          // handle 1
rclc_executor_add_subscription(...);                  // handle 2 ← CRASH

// Correct:
rclc_executor_init(&executor, &support.context, 2, &allocator);
```

---

## What's Next

→ [PWM LED Control](../PWM_LED_Control/README.md) — Use the subscriber pattern to control **real hardware** (LED brightness via PWM).
