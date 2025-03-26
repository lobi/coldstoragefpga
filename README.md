# Cold Storage Control System
FPGA Project - Semester 2

# Overview
The **Cold Storage Control System** is designed to monitor and regulate **temperature** and **humidity** in a cold storage environment. It uses a **DHT11** sensor to track temperature and humidity levels and controls a *Cooling Fan* and *Humidifier Machine* accordingly. The system is powered by an **FPGA** board (Zuboard 1CG), which reads sensor data and manages the cooling and humidifying devices. Additionally, the FPGA communicates with an **ESP8266** module via UART to transmit data to *ThingsBoard.cloud* for **visualization** and **remote control**.
![Cold Storage Control System](/docs/photos/full-system.jpg "Cold Storage Control System")

# Features
* **Real-time Monitoring**: Collects temperature and humidity data using the DHT11 sensor.
* **Automated Control**: Turns the Cooling Fan and Humidifier on/off based on predefined thresholds.
* **Cloud Integration**: Sends data to ThingsBoard.cloud via ESP8266 for remote monitoring and threshold setup.
* **FPGA-Based Control**: Uses the Zuboard 1CG FPGA for real-time processing and device control.

# Hardware Components
* **Zuboard 1CG FPGA** (Main controller)
* **DHT11 Sensor** (Temperature & Humidity measurement)
* **Cooling Fan** (Temperature regulation) - represented by a LED indicator
* **Humidifier Machine** (Humidity control) - represented by a LED indicator
* **ESP8266 Wi-Fi Module** (Data transmission to ThingsBoard)
* **Power Supply** (Appropriate voltage for all components)
* **Thingsboard.cloud** to visualization & remote control
* **USB UART FT232RL** (UART communication testing - during implementation)

# System workflow
![Work Flow](/docs/photos/WorkFlow.png "Work Flow")

## FPGA implementation
Block Design:
![Block Design](/docs/photos/EDA-Vivado-BlockDesign.png "Block Design")

RTL - Schematic:
![RTL - Schematic](/docs/photos/RTL-Schematic--top-module.png "RTL - Schematic")

Thingsboard:
![Thingsboard](/docs/photos/Thingsboard-Dashboard.png "Thingsboard")

# Software & Tools Used
* **Vivado 2024 EDA** (FPGA development environment for Zub 1CG)
* **Arduino IDE 2.3** (Ardiono development environment for ESP8266)
* **Hercules** for UART Comunication testing (Communication between FPGA and ESP8266)
* **ThingsBoard.cloud** (IoT Dashboard for visualization and control)
* **VSCode** (Code editor for Verilog and Arduino)

# Installation & Setup
## FPGA Code Deployment:
* Write Verilog code to interface with DHT11, Cooling Fan, and Humidifier.
* Implement UART communication between FPGA and ESP8266.
* Use Vivado 2024 to synthesize and deploy the code to Zuboard 1CG.

## ESP8266 Configuration:
* Flash ESP8266 with firmware to communicate with ThingsBoard.cloud.
* Set up Wi-Fi credentials for network access.
* Configure MQTT or HTTP API to send data to ThingsBoard.
* ThingsBoard.cloud Setup:
    * Create a new Device in ThingsBoard.
    * Configure Telemetry Data for Temperature and Humidity.
    * Set up Threshold Rules to automate Cooling Fan and Humidifier actions.
* Pins:
    * Zu 1CG FPGA's pins:
    ![Zub 1CG Pins](/docs/photos/DesignWrapper-IO-Ports.png "Zub 1CG Pins")
    * ESP8266 & full setup:
    ![hardware configuration](/docs/photos/wiring.jpg "hardware configuration")

# Video demo
[![Cold Storage Control System - FPGA Project](https://img.youtube.com/vi/w5AyaIGeWPU/0.jpg)](https://youtu.be/w5AyaIGeWPU)



