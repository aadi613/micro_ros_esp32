# Useful Links & References

> Official documentation, tutorials, and tools used in this project.

---

## micro-ROS

| Resource | Link |
|----------|------|
| Official Site | https://micro.ros.org |
| Documentation | https://micro.ros.org/docs/overview/ |
| GitHub Organization | https://github.com/micro-ROS |
| micro-ROS for ESP-IDF | https://github.com/micro-ROS/micro_ros_espidf_component |
| micro-ROS Agent | https://github.com/micro-ROS/micro-ROS-Agent |
| Supported Hardware | https://micro.ros.org/docs/overview/hardware/ |
| First micro-ROS app (ESP-IDF) | https://micro.ros.org/docs/tutorials/core/first_application_rtos/freertos/ |

---

## ROS 2 Humble

| Resource | Link |
|----------|------|
| Official Docs | https://docs.ros.org/en/humble/ |
| Installation Guide | https://docs.ros.org/en/humble/Installation.html |
| CLI Tools Tutorial | https://docs.ros.org/en/humble/Tutorials/Beginner-CLI-Tools.html |
| Understanding Topics | https://docs.ros.org/en/humble/Tutorials/Beginner-CLI-Tools/Understanding-ROS2-Topics.html |
| rclc GitHub | https://github.com/ros2/rclc |
| Message Types Reference | https://docs.ros2.org/humble/api/std_msgs/ |

---

## ESP32 / ESP-IDF

| Resource | Link |
|----------|------|
| ESP-IDF Getting Started | https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/ |
| ESP-IDF API Reference | https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/ |
| LEDC (PWM) Driver | https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/ledc.html |
| FreeRTOS on ESP-IDF | https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/system/freertos.html |
| GPIO Reference | https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/gpio.html |
| ESP32 Datasheet | https://www.espressif.com/sites/default/files/documentation/esp32_datasheet_en.pdf |
| ESP32 Technical Reference | https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf |

---

## Docker

| Resource | Link |
|----------|------|
| Docker Install (Linux) | https://docs.docker.com/engine/install/ubuntu/ |
| Docker CLI Reference | https://docs.docker.com/engine/reference/commandline/cli/ |
| ROS 2 Docker Images | https://hub.docker.com/_/ros |

---

## Serial Communication

| Resource | Link |
|----------|------|
| Linux Serial Port Guide | https://www.tldp.org/HOWTO/Serial-HOWTO.html |
| CH340 Driver (Linux) | https://www.wch-ic.com/downloads/CH341SER_LINUX_ZIP.html |
| CP210x Driver (Linux) | Built into kernel — `modprobe cp210x` |

---

## ROS 2 Standard Message Types

| Package | Common Types |
|---------|-------------|
| `std_msgs` | `Int32`, `Float32`, `Bool`, `String`, `Header` |
| `geometry_msgs` | `Twist`, `Pose`, `Point`, `Vector3`, `Quaternion` |
| `sensor_msgs` | `Imu`, `LaserScan`, `Image`, `JointState` |
| `nav_msgs` | `Odometry`, `Path`, `OccupancyGrid` |

Browse all types: https://docs.ros2.org/humble/api/

---

## Tutorials That Helped Build This Project

| Topic | Resource |
|-------|----------|
| micro-ROS publisher (FreeRTOS) | https://micro.ros.org/docs/tutorials/core/first_application_rtos/freertos/ |
| Understanding executors | https://micro.ros.org/docs/concepts/client_library/executor/ |
| ESP32 LEDC PWM example | https://github.com/espressif/esp-idf/tree/master/examples/peripherals/ledc |
| ROS 2 pub/sub tutorial | https://docs.ros.org/en/humble/Tutorials/Beginner-Client-Libraries/Writing-A-Simple-Cpp-Publisher-And-Subscriber.html |

---

## Tools Used

| Tool | Purpose | Link |
|------|---------|------|
| VS Code | Code editor | https://code.visualstudio.com |
| VS Code ESP-IDF Extension | Build/flash/monitor from VS Code | https://marketplace.visualstudio.com/items?itemName=espressif.esp-idf-extension |
| minicom | Serial terminal | `sudo apt install minicom` |
| PuTTY (Windows) | SSH + Serial terminal | https://putty.org |
| tmux | Multiple terminal panes in SSH | `sudo apt install tmux` |

---

## Community & Help

| Resource | Link |
|----------|------|
| ROS Discourse | https://discourse.ros.org |
| micro-ROS GitHub Issues | https://github.com/micro-ROS/micro_ros_espidf_component/issues |
| ESP-IDF GitHub Issues | https://github.com/espressif/esp-idf/issues |
| ROS Answers | https://answers.ros.org |
| Reddit r/ROS | https://www.reddit.com/r/ROS/ |
