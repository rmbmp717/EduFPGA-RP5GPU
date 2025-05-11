#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>

#define DEVICE "/dev/EduGPU_pcie_driver0"
#define BUFFER_SIZE 4

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <address in hex format> <data in hex format (4 bytes)>\n", argv[0]);
        return 1;
    }

    int fd;
    unsigned char buffer[BUFFER_SIZE];
    ssize_t bytes_written;
    off_t target_address = (off_t)strtol(argv[1], NULL, 16);

    // 4バイト刻みであるかをチェック
    if (target_address % 4 != 0) {
        fprintf(stderr, "Error: Address 0x%lx is not 4-byte aligned.\n", target_address);
        return 1;
    }

    // 書き込むデータを設定
    unsigned int data = (unsigned int)strtoul(argv[2], NULL, 16);
    for (int i = 0; i < BUFFER_SIZE; i++) {
        buffer[i] = (data >> (8 * (BUFFER_SIZE - 1 - i))) & 0xFF;
    }

    // デバイスファイルをライトオンリーでオープン
    fd = open(DEVICE, O_WRONLY);
    if (fd < 0) {
        perror("Failed to open device");
        return 1;
    }

    // オフセットを設定
    if (lseek(fd, target_address, SEEK_SET) == (off_t)-1) {
        perror("Failed to set offset");
        close(fd);
        return 1;
    }

    // デバイスにデータを書き込む
    bytes_written = write(fd, buffer, sizeof(buffer));
    if (bytes_written < 0) {
        perror("Failed to write to device");
        close(fd);
        return 1;
    }

    // 書き込んだデータを16進数で表示
    printf("Wrote %zd bytes to %s at address 0x%lx: \n", bytes_written, DEVICE, target_address);
    for (int i = 0; i < bytes_written; i++) {
        printf("%02x ", buffer[i]);  // 各バイトを16進数で表示
    }
    printf("\n");

    // デバイスファイルをクローズ
    close(fd);

    return 0;
}