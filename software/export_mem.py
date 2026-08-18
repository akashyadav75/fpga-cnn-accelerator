import os
import torch
import numpy as np
from torchvision import datasets, transforms
from train_model import MNIST_CNN

def float_to_q44_hex(val):
    """
    Converts a float value to an 8-bit Signed Q4.4 hex string.
    Range: -8.0 (0x80) to 7.875 (0x7F).
    """
    step = 1.0 / 16.0
    scaled = int(round(val / step))
    # Clip to signed 8-bit range [-128, 127]
    clipped = max(-128, min(127, scaled))
    # Convert to 8-bit unsigned representation for hex formatting
    if clipped < 0:
        clipped = 256 + clipped
    return f"{clipped:02X}"

def export_weights():
    # Load model
    model = MNIST_CNN()
    if not os.path.exists("model_q44.pth"):
        print("Error: model_q44.pth not found! Run train_model.py first.")
        return
    model.load_state_dict(torch.load("model_q44.pth", map_location=torch.device('cpu')))
    model.eval()

    mem_dir = "hardware/mem"
    os.makedirs(mem_dir, exist_ok=True)

    # 1. Export Conv1 Weights (4 channels, 1 input channel, 3x3 kernel)
    # Shape: [4, 1, 3, 3]
    w1 = model.conv1.weight.detach().numpy()
    b1 = model.conv1.bias.detach().numpy()
    
    # Export bias
    with open(f"{mem_dir}/conv1_bias.mem", "w") as f:
        for val in b1:
            f.write(f"{float_to_q44_hex(val)}\n")
            
    # Export weights channel-by-channel
    for out_ch in range(4):
        with open(f"{mem_dir}/conv1_weight_{out_ch}.mem", "w") as f:
            for r in range(3):
                for c in range(3):
                    f.write(f"{float_to_q44_hex(w1[out_ch, 0, r, c])}\n")

    # 2. Export Conv2 Weights (8 channels, 4 input channels, 3x3 kernel)
    # Shape: [8, 4, 3, 3]
    w2 = model.conv2.weight.detach().numpy()
    b2 = model.conv2.bias.detach().numpy()
    
    with open(f"{mem_dir}/conv2_bias.mem", "w") as f:
        for val in b2:
            f.write(f"{float_to_q44_hex(val)}\n")
            
    for out_ch in range(8):
        with open(f"{mem_dir}/conv2_weight_{out_ch}.mem", "w") as f:
            # Flatten weight for out_ch: 4 channels * 3 rows * 3 cols = 36 values
            for in_ch in range(4):
                for r in range(3):
                    for c in range(3):
                        f.write(f"{float_to_q44_hex(w2[out_ch, in_ch, r, c])}\n")

    # 3. Export FC Weights (10 output classes, 200 inputs)
    # Shape: [10, 200]
    # We must transpose PyTorch's CHW layout [10, 8, 5, 5] to hardware's HWC layout [10, 5, 5, 8]
    # so that the weights match our hardware's streaming channel order!
    wfc = model.fc.weight.detach().numpy() # Shape: [10, 200]
    wfc_reshaped = wfc.reshape(10, 8, 5, 5) # Reshape to [10, Ch, H, W]
    wfc_transposed = wfc_reshaped.transpose(0, 2, 3, 1) # Transpose to [10, H, W, Ch] (HWC)
    wfc_flat = wfc_transposed.reshape(10, 200) # Flatten back to [10, 200]
    
    bfc = model.fc.bias.detach().numpy()
    
    with open(f"{mem_dir}/fc_bias.mem", "w") as f:
        for val in bfc:
            f.write(f"{float_to_q44_hex(val)}\n")
            
    for out_ch in range(10):
        with open(f"{mem_dir}/fc_weight_{out_ch}.mem", "w") as f:
            for i in range(200):
                f.write(f"{float_to_q44_hex(wfc_flat[out_ch, i])}\n")

    print(f"Successfully exported all 8-bit .mem files to {mem_dir}/.")

    # 4. Export a few test images for verification/simulation
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    test_dataset = datasets.MNIST(root='./data', train=False, download=True, transform=transform)
    
    tb_dir = "verification/tb/data"
    os.makedirs(tb_dir, exist_ok=True)
    
    print("Exporting sample images for Testbench...")
    # Export 10 sample images
    for idx in range(10):
        img, label = test_dataset[idx]
        img_np = img.squeeze().numpy()
        
        with open(f"{tb_dir}/img_{idx}_label_{label}.mem", "w") as f:
            for r in range(28):
                for c in range(28):
                    f.write(f"{float_to_q44_hex(img_np[r, c])}\n")
                    
    # Create an index file of labels for validation
    with open(f"{tb_dir}/labels.txt", "w") as f:
        for idx in range(10):
            _, label = test_dataset[idx]
            f.write(f"{label}\n")

if __name__ == "__main__":
    export_weights()
