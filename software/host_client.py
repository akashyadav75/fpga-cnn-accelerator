import os
import sys
import time
import argparse
import serial
import numpy as np

# Try importing torchvision, fallback to reading input_1000.txt if torchvision is not present
try:
    from torchvision import datasets, transforms
    TORCHVISION_AVAILABLE = True
except ImportError:
    TORCHVISION_AVAILABLE = False


def load_mnist_test_images(limit=100):
    """
    Loads MNIST test images. If torchvision is available, it downloads/loads the true dataset.
    Otherwise, it falls back to reading from hardware/testvector/input_1000.txt.
    """
    if TORCHVISION_AVAILABLE:
        print("--- Loading MNIST Test Dataset via torchvision ---")
        transform = transforms.Compose([
            transforms.ToTensor(),
            transforms.Normalize((0.1307,), (0.3081,))
        ])
        test_dataset = datasets.MNIST(root='./data', train=False, download=True, transform=transform)
        images = []
        labels = []
        for i in range(min(limit, len(test_dataset))):
            img, label = test_dataset[i]
            # Convert to signed 8-bit Q4.4
            img_np = img.squeeze().numpy()
            step = 1.0 / 16.0
            scaled = np.round(img_np / step).astype(int)
            clipped = np.clip(scaled, -128, 127)
            # Map negative numbers to 8-bit unsigned representations [0, 255]
            clipped_u8 = np.where(clipped < 0, 256 + clipped, clipped).astype(np.uint8)
            images.append(clipped_u8.flatten())
            labels.append(label)
        return images, labels
    else:
        print("--- torchvision not found. Falling back to input_1000.txt ---")
        # Try to read from hardware/testvector/input_1000.txt
        testvector_path = "hardware/testvector/input_1000.txt"
        if not os.path.exists(testvector_path):
            # Try workspace root
            testvector_path = "../hardware/testvector/input_1000.txt"
            if not os.path.exists(testvector_path):
                print("Error: input_1000.txt not found. Cannot load test images.")
                sys.exit(1)
        
        with open(testvector_path, "r") as f:
            hex_lines = f.read().split()
        
        # input_1000.txt contains 1000 images, each 784 pixels.
        total_pixels = len(hex_lines)
        num_images = min(limit, total_pixels // 784)
        
        images = []
        labels = []
        for img_idx in range(num_images):
            start = img_idx * 784
            end = start + 784
            img_bytes = [int(x, 16) for x in hex_lines[start:end]]
            images.append(np.array(img_bytes, dtype=np.uint8))
            labels.append(img_idx % 10)  # The testbench assumes labels are j % 10
            
        return images, labels


def run_inference_on_board(port, baudrate, limit=100):
    images, labels = load_mnist_test_images(limit)
    
    print(f"Opening Serial Connection on {port} @ {baudrate} baud...")
    try:
        ser = serial.Serial(port, baudrate, timeout=5.0)
    except Exception as e:
        print(f"Error opening serial port: {e}")
        print("Make sure your Nexys Video board is plugged in and you specified the correct COM port.")
        return

    # Clear serial buffers
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    time.sleep(0.5)

    print(f"Starting End-to-End Inference for {len(images)} images...\n")
    correct = 0
    start_time = time.time()

    for idx, (img, label) in enumerate(zip(images, labels)):
        # Send 784-byte image
        ser.write(img.tobytes())
        ser.flush()

        # Read 1-byte response
        response_byte = ser.read(1)
        if len(response_byte) == 0:
            print(f"Image {idx+1}/{len(images)}: TIMEOUT waiting for prediction.")
            continue

        prediction = int.from_bytes(response_byte, byteorder='big')
        is_correct = (prediction == label)
        if is_correct:
            correct += 1
            status = "SUCCESS"
        else:
            status = "FAIL"

        print(f"Image {idx+1:03d} -> Label: {label} | Prediction: {prediction} | Status: {status}")

    total_time = time.time() - start_time
    accuracy = (correct / len(images)) * 100
    print("\n" + "="*50)
    print("                 INFERENCE RESULTS")
    print("="*50)
    print(f"Total Images Tested : {len(images)}")
    print(f"Correct Predictions  : {correct}")
    print(f"On-Board Accuracy    : {accuracy:.2f}%")
    print(f"Total Elapsed Time   : {total_time:.2f} seconds")
    print(f"Average Latency/Img  : {(total_time / len(images)) * 1000:.2f} ms")
    print("="*50)

    ser.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Host Client for FPGA CNN MNIST Accelerator")
    parser.add_argument("--port", type=str, required=True, help="COM / Serial port of Nexys Video (e.g., COM3, /dev/ttyUSB1)")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate (default: 115200)")
    parser.add_argument("--limit", type=int, default=100, help="Number of images to test (default: 100)")
    args = parser.parse_args()

    run_inference_on_board(args.port, args.baud, args.limit)
