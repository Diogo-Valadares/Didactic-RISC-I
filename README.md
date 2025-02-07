# Didactic-RISC-I
This project is part of a monography focused on transforming the RISC I architecture into a didactic tool.

![riscInternal](https://github.com/user-attachments/assets/5e4920f9-e34a-4daf-9f75-84d9e71b543a)

## Overview
This project focus on recriating the RISC I architecture to later improve it for didatic porpuses. Both the original RISC I recriation and DRISC archtectures will be contained in this repository for comparison.

The recriation was based on the works of [James B. Peek](https://www2.eecs.berkeley.edu/Pubs/TechRpts/1983/CSD-83-135.pdf) and [Manolis G. H. Katevenis](https://archive.org/details/reducedinstructi0000kate/mode/2up).
Although it's not a perfect replica, for reasons like simulation limitations and missing documentation, it can still reproduce the whole RISC I Instruction set, while keeping the same overall structucture.

An assembler, written in C#, has been developed to translate assembly language into machine code that can be directly read by the simulation model.

## Features
- Complete RISC I Simulation: A recreation of the RISC I architecture in Logisim Evolution.

- Custom Assembler: A  assembler written in C# for converting assembly language into executable code for the simulator.

- Educational Focus: Designed to be a comprehensive teaching tool for learning about computer architecture.

## Getting Started
To get started with the simulation and assembler, follow these steps:

1. Clone this repository to your local machine.

2. Open the Logisim Evolution project file to explore the RISC I architecture.

3. Use the provided C# assembler to compile assembly code into machine code for the simulator.

