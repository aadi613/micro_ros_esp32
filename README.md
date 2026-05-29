# micro-ROS on ESP32

This repository documents the process of learning and implementing micro-ROS on ESP32 using ROS 2 Humble.

The goal is to progressively build communication between ROS 2 and ESP32, starting from basic publishers and subscribers and ending with hardware control through PWM.

## Learning Path

Environment Setup

↓

Hardware Setup

↓

ESP32 Publisher

↓

ESP32 Subscriber

↓

ROS2 ↔ ESP32 Communication

↓

PWM LED Brightness Control

## Repository Structure

### Environment_Setup

Installation and verification of ROS 2, micro-ROS, ESP-IDF, and supporting tools.

### Hardware_Setup

ESP32 hardware information, serial connection details, and common hardware-related issues.

### ESP32_Publisher

Publishing Int32 messages from ESP32 to ROS 2.

### ESP32_Subscriber

Receiving Int32 messages from ROS 2 on ESP32.

### ROS2_to_ESP32_Communication

Understanding how ROS 2 nodes communicate with ESP32 through the micro-ROS Agent.

### PWM_LED_Control

Using ROS 2 messages to control LED brightness on ESP32 through PWM.

### Troubleshooting

Common issues encountered during development and their solutions.

## Communication Architecture

ROS2 Node

↓

ROS Topic

↓

micro_ros_agent

↓

Serial / UDP Transport

↓

ESP32 Node

## Final Demonstration

ROS2 Publisher

↓

/led_brightness

↓

ESP32 Subscriber

↓

PWM Driver

↓

LED Brightness Control

## Hardware Used

* ESP32 DevKit V1
* USB Data Cable
* Ubuntu 22.04 LTS

## Software Used

* ROS 2 Humble
* micro_ros_setup
* micro_ros_agent
* ESP-IDF
* FreeRTOS

