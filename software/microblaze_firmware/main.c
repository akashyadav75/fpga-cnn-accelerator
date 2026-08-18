/******************************************************************************
* MicroBlaze Firmware for MNIST CNN Accelerator
* Target: Nexys Video Board (Artix-7)
* 
* Description:
* Receives a 784-byte MNIST image from the Host PC via UART, sends it through
* the AXI-Stream FIFO to the hardware CNN Accelerator, reads the classification
* result, and sends the result back to the Host PC via UART.
******************************************************************************/

#include <stdio.h>
#include "xparameters.h"
#include "xuartlite.h"
#include "xllfifo.h"
#include "xil_types.h"

#define IMAGE_SIZE 784

// Instance pointers
XUartLite UartInstance;
XLlFifo FifoInstance;

// Function declarations
int init_peripherals(void);
void stream_image_and_get_prediction(void);

int main(void) {
    int status;

    // Initialize UART and FIFO peripherals
    status = init_peripherals();
    if (status != XST_SUCCESS) {
        return -1;
    }

    // Main execution loop
    while (1) {
        stream_image_and_get_prediction();
    }

    return 0;
}

int init_peripherals(void) {
    int status;
    XLlFifo_Config *fifo_config;

    // 1. Initialize AXI UART Lite (Using Base Address for Vitis 2025.2 SDT compatibility)
    status = XUartLite_Initialize(&UartInstance, XPAR_AXI_UARTLITE_0_BASEADDR);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    // 2. Initialize AXI-Stream FIFO (Using Base Address for Vitis 2025.2 SDT compatibility)
    fifo_config = XLlFfio_LookupConfig(XPAR_AXI_FIFO_0_BASEADDR);
    if (!fifo_config) {
        return XST_FAILURE;
    }

    status = XLlFifo_CfgInitialize(&FifoInstance, fifo_config, fifo_config->BaseAddress);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    // Reset FIFO
    XLlFifo_Reset(&FifoInstance);

    return XST_SUCCESS;
}

void stream_image_and_get_prediction(void) {
    u8 image_buffer[IMAGE_SIZE];
    u32 bytes_received = 0;
    u8 prediction = 0xFF;
    u32 rx_word;

    // 1. Read exactly 784 bytes (one MNIST image) from UART
    while (bytes_received < IMAGE_SIZE) {
        bytes_received += XUartLite_Recv(&UartInstance, &image_buffer[bytes_received], IMAGE_SIZE - bytes_received);
    }

    // 2. Write the 784-byte image into the AXI-Stream FIFO Transmit channel
    // Check available space in FIFO TX buffer (must be at least 784 bytes / 196 words of 32-bits)
    while (XLlFifo_TxVacancy(&FifoInstance) < (IMAGE_SIZE / 4 + 1)) {
        // Wait for FIFO vacancy
    }

    // Write image data in 32-bit words (each word contains 4 pixels)
    for (int i = 0; i < IMAGE_SIZE; i += 4) {
        u32 word = (image_buffer[i]     << 24) | 
                   (image_buffer[i + 1] << 16) | 
                   (image_buffer[i + 2] << 8)  | 
                   (image_buffer[i + 3]);
        XLlFifo_TxPutWord(&FifoInstance, word);
    }

    // Start transmission by writing the transaction length (784 bytes) to the FIFO
    XLlFifo_iTxSetLen(&FifoInstance, IMAGE_SIZE);

    // 3. Wait for the CNN Accelerator to complete and push the result into FIFO RX channel
    while (XLlFifo_RxOccupancy(&FifoInstance) == 0) {
        // Wait for prediction result
    }

    // 4. Read the prediction result from the FIFO
    // The prediction is packed in the lower 8 bits of the 32-bit word
    rx_word = XLlFifo_RxGetWord(&FifoInstance);
    prediction = (u8)(rx_word & 0xFF);

    // 5. Send the 1-byte prediction result back to the Host PC via UART
    XUartLite_Send(&UartInstance, &prediction, 1);
}
