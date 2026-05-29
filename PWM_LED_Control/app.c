#include <rcl/rcl.h>
#include <rcl/error_handling.h>
#include <rclc/rclc.h>
#include <rclc/executor.h>

#include <std_msgs/msg/int32.h>

#include <stdio.h>

#ifdef ESP_PLATFORM
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/ledc.h"
#endif

#include <unistd.h>

#define RCCHECK(fn) { \
    rcl_ret_t temp_rc = fn; \
    if((temp_rc != RCL_RET_OK)){ \
        printf("Failed status on line %d: %d. Aborting.\n",__LINE__,(int)temp_rc); \
        vTaskDelete(NULL); \
    } \
}

#define RCSOFTCHECK(fn) { \
    rcl_ret_t temp_rc = fn; \
    if((temp_rc != RCL_RET_OK)){ \
        printf("Failed status on line %d: %d. Continuing.\n",__LINE__,(int)temp_rc); \
    } \
}

#define LED_PIN 2

#define LEDC_TIMER      LEDC_TIMER_0
#define LEDC_MODE       LEDC_HIGH_SPEED_MODE
#define LEDC_CHANNEL    LEDC_CHANNEL_0
#define LEDC_DUTY_RES   LEDC_TIMER_8_BIT
#define LEDC_FREQUENCY  5000

rcl_subscription_t subscriber;
std_msgs__msg__Int32 msg;

void subscription_callback(const void * msgin)
{
    const std_msgs__msg__Int32 * msg =
        (const std_msgs__msg__Int32 *)msgin;

    int brightness = msg->data;

    if(brightness < 0)
        brightness = 0;

    if(brightness > 255)
        brightness = 255;

    ledc_set_duty(
        LEDC_MODE,
        LEDC_CHANNEL,
        brightness);

    ledc_update_duty(
        LEDC_MODE,
        LEDC_CHANNEL);

    printf("Brightness = %d\n", brightness);
}

void appMain(void * arg)
{
    rcl_allocator_t allocator = rcl_get_default_allocator();
    rclc_support_t support;

    // Initialize micro-ROS
    RCCHECK(rclc_support_init(&support, 0, NULL, &allocator));

    // Configure PWM Timer
    ledc_timer_config_t ledc_timer = {
        .speed_mode = LEDC_MODE,
        .timer_num = LEDC_TIMER,
        .duty_resolution = LEDC_DUTY_RES,
        .freq_hz = LEDC_FREQUENCY,
        .clk_cfg = LEDC_AUTO_CLK
    };

    ledc_timer_config(&ledc_timer);

    // Configure PWM Channel
    ledc_channel_config_t ledc_channel = {
        .gpio_num = LED_PIN,
        .speed_mode = LEDC_MODE,
        .channel = LEDC_CHANNEL,
        .timer_sel = LEDC_TIMER,
        .duty = 0,
        .hpoint = 0
    };

    ledc_channel_config(&ledc_channel);

    // Create node
    rcl_node_t node;
    RCCHECK(
        rclc_node_init_default(
            &node,
            "led_pwm_control",
            "",
            &support
        )
    );

    // Create subscriber
    RCCHECK(
        rclc_subscription_init_default(
            &subscriber,
            &node,
            ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, Int32),
            "/led_brightness"
        )
    );

    // Create executor
    rclc_executor_t executor;
    RCCHECK(
        rclc_executor_init(
            &executor,
            &support.context,
            1,
            &allocator
        )
    );

    RCCHECK(
        rclc_executor_add_subscription(
            &executor,
            &subscriber,
            &msg,
            &subscription_callback,
            ON_NEW_DATA
        )
    );

    while(1)
    {
        rclc_executor_spin_some(
            &executor,
            RCL_MS_TO_NS(100)
        );

        usleep(100000);
    }

    RCCHECK(rcl_subscription_fini(&subscriber, &node));
    RCCHECK(rcl_node_fini(&node));

    vTaskDelete(NULL);
}
