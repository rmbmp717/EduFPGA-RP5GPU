#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>

#define DEVICE "/dev/EduGPU_pcie_driver0"
#define BUFFER_SIZE 4

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <32-bit data in hex format>\n", argv[0]);
        return 1;
    }

    int fd;
    unsigned char buffer[BUFFER_SIZE];
    ssize_t bytes_written;
    off_t target_address = 0xF800;  // Write target offset

    printf("0x00000001: Program Write\n");
    printf("0x00000002: Data Write\n");
    printf("0x00000080: GPU Start\n");
    printf("0x00000100: GPU Soft Reset\n");

    // Convert input argument to 32-bit data and set buffer
    unsigned int data = (unsigned int)strtoul(argv[1], NULL, 16);
    buffer[0] = (data >> 24) & 0xFF;
    buffer[1] = (data >> 16) & 0xFF;
    buffer[2] = (data >> 8) & 0xFF;
    buffer[3] = data & 0xFF;

    // Open the device file in write-only mode
    fd = open(DEVICE, O_WRONLY);
    if (fd < 0) {
        perror("Failed to open device");
        return 1;
    }

    // Set the offset
    if (lseek(fd, target_address, SEEK_SET) == (off_t)-1) {
        perror("Failed to set offset");
        close(fd);
        return 1;
    }

    // Write data to the device
    bytes_written = write(fd, buffer, sizeof(buffer));
    if (bytes_written < 0) {
        perror("Failed to write to device");
        close(fd);
        return 1;
    }

    // Display the written data in hexadecimal using print
    printf("Wrote %zd bytes to %s at address 0x%lx: \n", bytes_written, DEVICE, target_address);
    printf("Written data: 0x%08x\n", data);

    // Close the device file
    close(fd);

    return 0;
}