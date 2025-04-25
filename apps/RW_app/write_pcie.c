#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#define DEVICE "/dev/EduGraphics_pcie_driver0"
#define BUFFER_SIZE 4

int main() {
    int fd;
    unsigned char buffer[BUFFER_SIZE];
    ssize_t bytes_written;
    off_t target_address = 0x014;  // 書き込み先のオフセット

    // 0x01 から 0x04 までのデータをバッファにセット
    for (int i = 0; i < BUFFER_SIZE; i++) {
        buffer[i] = i + 4;  // 0x07, 0x08, 0x09, 0x0a
        //buffer[i] = 0x01;  // 0x07, 0x08, 0x09, 0x0a
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
