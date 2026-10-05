# EARS — Environmental Acoustic Recording System

**EARS (Environmental Acoustic Recording System)** is a field-deployable device for **long-duration autonomous recording of environmental sound** for subsequent soundscape analysis.

An EARS unit is intended to operate autonomously for months in locations such as forest canopies, rooftops, villages, and other remote or difficult-to-access sites.

## System overview

An EARS unit contains:

- A high-quality microphone
- A Raspberry Pi
- A microcontroller with cellular modem
- A large-capacity SSD
- A large Li-ion battery
- Power-management and charging electronics

A solar panel connected to the battery is mounted externally.

The Raspberry Pi continuously records audio to the SSD. The current recording format is **44.1 kHz, 12-bit WAV**, with each file containing **10 seconds of audio**.

The Raspberry Pi also performs local processing and manages the stored audio files.

The microcontroller monitors the system and uses the cellular modem to transmit metadata about the recordings to a remote server using **MQTT**. The system does not normally transmit the audio files over the cellular network because of their large volume and the associated bandwidth and energy requirements.

## dataMule: retrieving the audio

EARS uses a human-assisted data retrieval system called **dataMule**.

When the remote server determines that an EARS unit is approaching its storage capacity, a ranger is dispatched to retrieve the stored audio.

The ranger does not need to physically connect a cable to the EARS unit. Instead:

1. The ranger approaches the EARS unit and sends a Bluetooth signal.
2. The EARS unit detects the signal and activates a local Wi-Fi network using the Raspberry Pi.
3. The ranger connects a laptop to this Wi-Fi network.
4. A web interface allows the ranger to download the stored audio files.
5. Files can be removed from the EARS SSD only after successful download.

Thus, **cellular communication is used for low-bandwidth metadata, while high-volume audio is transferred over a short-range Wi-Fi connection**. This is expected to be substantially more practical and energy efficient for remote deployments.

## Repository contents

This repository contains the hardware, software, and documentation required to develop and deploy EARS systems.

```text
hardware/       Circuit diagrams, PCB and hardware files
mechanical/     Enclosure and mechanical design
firmware/       Embedded C firmware for the microcontroller
raspberry_pi/   Python software running on the Raspberry Pi
docs/           System and implementation documentation
```

Detailed documentation will include:

- System architecture
- Circuit diagrams
- Bill of materials
- Mechanical/enclosure drawings
- Power system
- Audio recording system
- MQTT communication and metadata
- dataMule protocol and software
- Deployment instructions

**[Placeholder: Add links to documentation sections.]**

**[Placeholder: Add photographs of the EARS prototype.]**

## Project status

EARS is currently under development. The hardware and software architecture, dataMule system, and field-deployment procedures will evolve through prototype development and field testing.

## Acknowledgements

EARS is being developed at **Indian Institute of Technology Guwahati (IIT Guwahati)**.

**[Placeholder: Add research group/centre, collaborators, funding, and project links.]**

## License

**[Placeholder: Add software, hardware, and documentation licenses.]**
