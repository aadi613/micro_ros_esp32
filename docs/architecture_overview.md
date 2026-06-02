# System Architecture Overview

> How the Laptop, Raspberry Pi, and ESP32 connect and communicate using micro-ROS and ROS 2 Humble.

---

## High-Level System Diagram

```
╔══════════════════════════════════════════════════════════════════╗
║                         LAPTOP                                   ║
║  (Windows / Ubuntu)                                              ║
║                                                                  ║
║  ┌──────────────────┐    ┌───────────────────────────────────┐   ║
║  │  VS Code / SSH   │    │  ESP-IDF Toolchain                │   ║
║  │  Terminal        │    │  idf.py build / flash / monitor   │   ║
║  └────────┬─────────┘    └───────────────┬───────────────────┘   ║
║           │ SSH                          │ USB Serial (flash)    ║
╚═══════════╪══════════════════════════════╪═══════════════════════╝
            │                              │
            ▼ SSH                          ▼ USB
╔═══════════════════════════╗   ╔═════════════════════════════════╗
║     RASPBERRY PI          ║   ║          ESP32                  ║
║                           ║   ║                                 ║
║  ┌─────────────────────┐  ║   ║  ┌───────────────────────────┐  ║
║  │  Docker Container   │  ║   ║  │  FreeRTOS                 │  ║
║  │  ros2_humble        │  ║   ║  │                           │  ║
║  │                     │  ║   ║  │  micro_ros_task           │  ║
║  │  ┌───────────────┐  │  ║   ║  │  ├── rclc_support_init   │  ║
║  │  │ ROS 2 Humble  │  │  ║   ║  │  ├── Publisher (1 Hz)    │  ║
║  │  │               │  │  ║   ║  │  ├── Subscriber          │  ║
║  │  │  Topics:      │  │  ║   ║  │  └── Executor spin       │  ║
║  │  │  /encoder  ◄──┼──┼──╫──►│  │                           │  ║
║  │  │  /imu      ◄──┼──┼──╫──►│  │  Hardware:               │  ║
║  │  │  /cmd_vel  ──►┼──┼──╫──►│  │  ├── GPIO 2 (LED/PWM)   │  ║
║  │  └───────┬───────┘  │  ║   ║  │  ├── LEDC (PWM timer)   │  ║
║  │          │           │  ║   ║  │  └── UART0 (serial)     │  ║
║  │  ┌───────▼────────┐  │  ║   ║  └───────────────────────────┘  ║
║  │  │ micro-ROS      │◄─┼──╫──►│                                 ║
║  │  │ Agent          │  │  ║   ║                                 ║
║  │  │ (serial trans) │  │  ║   ║                                 ║
║  │  └────────────────┘  │  ║   ║                                 ║
║  └─────────────────────┘  ║   ╚═════════════════════════════════╝
║                           ║         ▲
║                           ║         │ USB Serial
╚═══════════════════════════╝         │ (/dev/ttyUSB0)
            │ USB Cable ──────────────┘
```

---

## Communication Layers

```
ROS 2 Application Layer
    ┌──────────────────────────────────────────────┐
    │  ros2 topic pub / ros2 topic echo            │
    │  ros2 node list / ros2 topic list            │
    └──────────────────────┬───────────────────────┘
                           │ DDS (rmw)
    ┌──────────────────────▼───────────────────────┐
    │  micro-ROS Agent                             │
    │  Bridges DDS ↔ XRCE-DDS protocol            │
    └──────────────────────┬───────────────────────┘
                           │ XRCE-DDS over Serial
    ┌──────────────────────▼───────────────────────┐
    │  micro-ROS Client (on ESP32)                 │
    │  rclc: node, publisher, subscriber, executor │
    └──────────────────────────────────────────────┘
```

| Layer | Technology | Where |
|-------|-----------|-------|
| User interface | `ros2 cli` | Laptop / Pi |
| Middleware | ROS 2 rmw (DDS) | Raspberry Pi Docker |
| Bridge | micro-ROS Agent (XRCE-DDS) | Raspberry Pi Docker |
| Transport | USB Serial (115200 baud) | Pi ↔ ESP32 physical cable |
| Client | rclc micro-ROS library | ESP32 firmware |
| Hardware | LEDC, GPIO, UART | ESP32 silicon |

---

## Data Flow

### ESP32 → ROS 2 (Publishing)

```
ESP32 timer fires (1 Hz)
    │
    ▼
timer_callback()
    │  msg.data++
    │
    ▼
rcl_publish(&publisher, &msg, NULL)
    │
    ▼
micro-ROS serializer (CDR encoding)
    │
    ▼
UART TX (GPIO 1) → USB Cable
    │
    ▼
/dev/ttyUSB0 on Raspberry Pi
    │
    ▼
micro-ROS Agent (deserializes XRCE-DDS)
    │
    ▼
DDS publisher → ROS 2 topic /encoder
    │
    ▼
ros2 topic echo /encoder  (laptop or Pi)
```

### ROS 2 → ESP32 (Subscribing)

```
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist ...
    │
    ▼
ROS 2 DDS
    │
    ▼
micro-ROS Agent (serializes to XRCE-DDS)
    │
    ▼
UART TX → USB Cable → ESP32 UART RX
    │
    ▼
micro-ROS deserializer
    │
    ▼
rclc_executor calls subscription_callback()
    │
    ▼
Hardware action (set PWM, drive motor, etc.)
```

---

## Topic Map

```
             ┌─────────────────────────────────────┐
             │           ROS 2 Topic Space          │
             │                                      │
ESP32 ──────►│  /encoder         (Int32)            │──────► Monitor
ESP32 ──────►│  /imu             (Imu)              │──────► Monitor
             │                                      │
             │  /cmd_vel         (Twist)            │◄────── Nav Stack
             │  /motor_cmd       (Int32)            │◄────── User
             │  /led_brightness  (Int32)            │◄────── User / Script
             │  /led_cmd         (Bool)             │◄────── User / Script
             │                                      │
             └─────────────────────────────────────┘
                             ▲ ▼
                      micro-ROS Agent
                             ▲ ▼
                      USB Serial Transport
                             ▲ ▼
                           ESP32
```

---

## Node Graph

```
/micro_ros_agent
    ├── Bridges all topics between ROS 2 and ESP32

/esp32_node  (or /pwm_led_node, /esp32_publisher_node, etc.)
    ├── Publishers:  /encoder, /imu
    └── Subscribers: /cmd_vel, /motor_cmd, /led_brightness
```

---

## Future Architecture (Rover)

```
Laptop
  │ SSH + RViz + teleop_twist_keyboard
  ▼
Raspberry Pi
  ├── ROS 2 Nav Stack (Navigation 2)
  ├── SLAM (slam_toolbox)
  ├── micro-ROS Agent
  └── USB Serial
        ▼
ESP32
  ├── Publisher: /encoder (left + right)
  ├── Publisher: /imu     (MPU6050)
  ├── Subscriber: /cmd_vel → motor PWM
  └── Motor Driver (L298N / TB6612)
        ├── Left Motor (PWM + DIR)
        └── Right Motor (PWM + DIR)
```
