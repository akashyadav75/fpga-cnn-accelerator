import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
import numpy as np

# Set random seed for reproducibility
torch.manual_seed(42)

# Define hardware-friendly CNN
class MNIST_CNN(nn.Module):
    def __init__(self):
        super(MNIST_CNN, self).__init__()
        # Conv1: 1 input channel, 4 output channels, 3x3 kernel, stride=1, padding=0
        self.conv1 = nn.Conv2d(1, 4, kernel_size=3, stride=1, padding=0, bias=True)
        self.pool1 = nn.MaxPool2d(kernel_size=2, stride=2) # 26x26 -> 13x13
        
        # Conv2: 4 input channels, 8 output channels, 3x3 kernel, stride=1, padding=0
        self.conv2 = nn.Conv2d(4, 8, kernel_size=3, stride=1, padding=0, bias=True)
        self.pool2 = nn.MaxPool2d(kernel_size=2, stride=2) # 11x11 -> 5x5
        
        # Fully Connected (FC): 5*5*8 = 200 inputs, 10 outputs (classes 0-9)
        self.fc = nn.Linear(5 * 5 * 8, 10, bias=True)
        self.relu = nn.ReLU()

    def forward(self, x):
        x = self.relu(self.conv1(x))
        x = self.pool1(x)
        x = self.relu(self.conv2(x))
        x = self.pool2(x)
        x = x.view(-1, 5 * 5 * 8)
        x = self.fc(x)
        return x

def quantize_to_q44(tensor):
    """
    Simulates Signed Q4.4 fixed-point quantization:
    1 Sign bit, 3 Integer bits, 4 Fractional bits.
    Range: -8.0 to +7.875, step = 0.0625.
    """
    step = 1.0 / 16.0  # 2^-4
    q_min = -128       # -8.0 * 16
    q_max = 127        # 7.875 * 16
    
    # Scale, round, clip, and scale back
    scaled = torch.round(tensor / step)
    clipped = torch.clamp(scaled, q_min, q_max)
    return clipped * step

def train():
    # Load dataset
    try:
        transform = transforms.Compose([
            transforms.ToTensor(),
            transforms.Normalize((0.1307,), (0.3081,)) # standard MNIST normalization
        ])
        
        train_dataset = datasets.MNIST(root='./data', train=True, download=True, transform=transform)
        test_dataset = datasets.MNIST(root='./data', train=False, download=True, transform=transform)
        
        train_loader = DataLoader(train_dataset, batch_size=64, shuffle=True)
        test_loader = DataLoader(test_dataset, batch_size=1000, shuffle=False)
    except Exception as e:
        print(f"MNIST download skipped or failed ({e}). Falling back to synthetic fast training data...")
        # Create synthetic fast dataset
        class SyntheticMNIST(torch.utils.data.Dataset):
            def __init__(self, size=128):
                self.size = size
                self.data = torch.randn(size, 1, 28, 28)
                self.labels = torch.randint(0, 10, (size,))
            def __len__(self):
                return self.size
            def __getitem__(self, idx):
                return self.data[idx], self.labels[idx]
        
        train_loader = DataLoader(SyntheticMNIST(128), batch_size=32, shuffle=True)
        test_loader = DataLoader(SyntheticMNIST(32), batch_size=32, shuffle=False)
    
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = MNIST_CNN().to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=0.01)
    
    print("Training hardware-friendly MNIST CNN...")
    for epoch in range(2):  # 2 epochs
        model.train()
        running_loss = 0.0
        for images, labels in train_loader:
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            running_loss += loss.item()
        print(f"Epoch {epoch+1}/2 - Loss: {running_loss/len(train_loader):.4f}")
        
    # Evaluate model accuracy (Floating point vs Quantized)
    model.eval()
    float_correct = 0
    quant_correct = 0
    total = 0
    
    # Create a quantized clone of the model weights for evaluation
    with torch.no_grad():
        for images, labels in test_loader:
            images, labels = images.to(device), labels.to(device)
            
            # Floating Point Inference
            float_outputs = model(images)
            _, float_preds = torch.max(float_outputs, 1)
            float_correct += (float_preds == labels).sum().item()
            
            # Simulated Quantized Inference
            x = quantize_to_q44(images)
            
            # Conv1
            w1_q = quantize_to_q44(model.conv1.weight)
            b1_q = quantize_to_q44(model.conv1.bias)
            x = nn.functional.conv2d(x, w1_q, b1_q, stride=1, padding=0)
            x = model.relu(x)
            x = quantize_to_q44(x)
            x = model.pool1(x)
            
            # Conv2
            w2_q = quantize_to_q44(model.conv2.weight)
            b2_q = quantize_to_q44(model.conv2.bias)
            x = nn.functional.conv2d(x, w2_q, b2_q, stride=1, padding=0)
            x = model.relu(x)
            x = quantize_to_q44(x)
            x = model.pool2(x)
            
            # FC
            x = x.view(-1, 5 * 5 * 8)
            wfc_q = quantize_to_q44(model.fc.weight)
            bfc_q = quantize_to_q44(model.fc.bias)
            x = nn.functional.linear(x, wfc_q, bfc_q)
            
            _, quant_preds = torch.max(x, 1)
            quant_correct += (quant_preds == labels).sum().item()
            total += labels.size(0)
            
    print(f"\nFinal Test Accuracy:")
    print(f"  Floating-Point Model: {float_correct / total * 100:.2f}%")
    print(f"  Quantized Q4.4 Model: {quant_correct / total * 100:.2f}%")
    
    # Save the floating-point model weights
    torch.save(model.state_dict(), "model_q44.pth")
    print("Model weights successfully saved to 'model_q44.pth'.")

if __name__ == "__main__":
    train()
