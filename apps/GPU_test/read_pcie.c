#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>

#define DEVICE "/dev/EduGPU_pcie_driver0"
#define BUFFER_SIZE 4

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <address in hex format>\n", argv[0]);
        return 1;
    }

    int fd;
    char buffer[BUFFER_SIZE];
    ssize_t bytes_read;
    off_t target_address = (off_t)strtol(argv[1], NULL, 16);

    // 4バイト刻みであるかをチェック
    if (target_address % 4 != 0) {
        fprintf(stderr, "Error: Address 0x%lx is not 4-byte aligned.\n", target_address);
        return 1;
    }

    perror("Read start");

    // デバイスファイルを読み取り専用でオープン
    fd = open(DEVICE, O_RDONLY);
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

    // デバイスからデータを読み取る
    bytes_read = read(fd, buffer, sizeof(buffer));
    if (bytes_read < 0) {
        perror("Failed to read from device");
        close(fd);
        return 1;
    }

    // 読み取ったデータを16進数で表示
    printf("Read %zd bytes from %s at address 0x%lx: \n", bytes_read, DEVICE, target_address);
    for (int i = 0; i < bytes_read; i++) {
        printf("%02x ", buffer[i]);  // 各バイトを16進数で表示
    }
    printf("\n");

    // デバイスファイルをクローズ
    close(fd);

    return 0;
}