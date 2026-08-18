[README.md](https://github.com/user-attachments/files/31194971/README.md)
# fpga-cnn-accelerator
Hardware-software co-design of a Convolutional Neural Network built with PyTorch and Verilog HDL.
# FPGA-based CNN Accelerator for MNIST Digit Classification (8-Bit Quantized)

This repository contains a fully pipelined, streaming CNN hardware accelerator designed for MNIST digit classification on FPGAs (specifically targeting the Artix-7 on the **Nexys Video** board).

The system uses **8-bit Signed Q4.4 Fixed-Point Arithmetic** to achieve high classification accuracy ($>95\%$) while keeping hardware resource usage (LUTs, FFs, DSPs, BRAMs) extremely low.

---

## Directory Structure
```
fpga-cnn-accelerator/
│
├── software/                      # PyTorch Domain
│   ├── train_model.py             # Defines and trains the CNN (with Q4.4 simulation)
│   ├── export_mem.py              # Script that generates 8-bit signed hex .mem files
│   └── requirements.txt           # Software Python dependencies
│
├── hardware/                      # RTL & Physical Design Domain
│   ├── src/                       # Verilog Design Sources
│   │   ├── axis_cnn_mnist.v       # TOP MODULE (AXI-Stream Interface)
│   │   ├── conv1_layer/           # Conv1 layer components
│   │   │   ├── conv1_layer.v
│   │   │   ├── conv1_buf.v        # Line buffer (28x28 image)
│   │   │   └── conv1_calc.v       # Parallel 3x3 convolution multipliers
│   │   ├── conv2_layer/           # Conv2 layer components
│   │   │   ├── conv2_layer.v
│   │   │   ├── conv2_buf.v        # Line buffer (13x13 feature map)
│   │   │   └── conv2_calc.v       # Multi-channel convolution multipliers
│   │   ├── maxpool_relu.v         # Max Pooling & ReLU for Conv1
│   │   ├── maxpool_relu_2.v       # Max Pooling & ReLU for Conv2
│   │   ├── fully_connected.v      # Dense layer (Time-Multiplexed MACs)
│   │   └── comparator.v           # ArgMax class selector (0-9)
│   │
│   ├── constraints/               
│   │   └── nexys_video.xdc        # Nexys Video Pinout and 100 MHz Clock constraint
│   │
│   ├── mem/                       # Quantized 8-bit Hex Memory Initialization Files
│   │   ├── conv1_bias.mem
│   │   ├── conv1_weight_0.mem
│   │   └── ... (all 16 .mem files)
│   │
│   └── scripts/
│       └── build_project.tcl      # Automation script to build Vivado project
│
├── verification/                  # Simulation Domain
│   └── tb/
│       ├── data/                  # Quantized sample MNIST images for simulation
│       ├── top_tb.v               # Base testbench (passes 1 test image)
│       └── axis_cnn_mnist_1000_tb.v # Regression testbench (passes 10 test images)
│
├── docs/                          # Engineering Documentation
│   └── reports/                   # Static exports from Vivado Analysis
│       ├── post_route_timing.rpt  # Proves clock constraint is met (WNS > 0)
│       ├── utilization.rpt        # Proves LUT/FF/BRAM/DSP efficiency
│       └── power.rpt              # Estimated power dissipation
│
└── README.md                      # Project setup & usage guide
```

---

## Getting Started

### 1. Software Setup & Quantization
First, install the Python dependencies:
```bash
pip install -r software/requirements.txt
```

Train the CNN model:
```bash
python software/train_model.py
```
*This will train the CNN on MNIST and simulate the 8-bit Q4.4 accuracy, reaching $>95\%$ accuracy.*

Export the trained weights, biases, and sample images to hexadecimal `.mem` files:
```bash
python software/export_mem.py
```

### 2. RTL Simulation
To verify the hardware correctness, load the files in your favorite HDL Simulator (e.g., **Vivado Simulator**, **ModelSim**, or **Icarus Verilog**):
* Compile all `.v` files inside `hardware/src/` and its subdirectories.
* Load the testbench `verification/tb/axis_cnn_mnist_1000_tb.v`.
* Run the simulation to verify that the hardware correctly classifies all 10 sample test images with $100\%$ accuracy!

### 3. Build Vivado Project
To synthesize, implement, and generate the programming bitstream automatically:
1. Open Vivado.
2. Open the Vivado Tcl Console.
3. Navigate to the project root directory.
4. Run:
   ```tcl
   source ./hardware/scripts/build_project.tcl
   ```
This will automatically generate the project, run synthesis and implementation, and export post-route timing, utilization, and power reports into `docs/reports/`.
