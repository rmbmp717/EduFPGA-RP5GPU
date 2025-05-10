#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#define DEVICE "/dev/EduGraphics_pcie_driver0"
#define FPGA "FPGA"

int write_to_device(unsigned int data, off_t offset) {
    int fd;
    ssize_t bytes_written;
    unsigned char write_buffer[4];  // 4バイトのバッファ

    // アドレスが4バイトごとかを確認
    if (offset % 4 != 0) {
        fprintf(stderr, "Error: Address 0x%lx is not 4-byte aligned.\n", offset);
        return 1;
    }

    // デバイスファイルをライトオンリーでオープン
    fd = open(DEVICE, O_WRONLY);
    if (fd < 0) {
        perror("Failed to open device for writing");
        return 1;
    }

    // 32ビットのデータをバイトごとに分解して書き込みバッファに設定
    write_buffer[0] = (data >> 24) & 0xFF;  // 上位バイト
    write_buffer[1] = (data >> 16) & 0xFF;
    write_buffer[2] = (data >> 8) & 0xFF;
    write_buffer[3] = data & 0xFF;          // 下位バイト

    // オフセットを設定
    if (lseek(fd, offset, SEEK_SET) == (off_t)-1) {
        perror("Failed to set offset for writing");
        close(fd);
        return 1;
    }

    // デバイスにデータを書き込む（4バイト）
    bytes_written = write(fd, write_buffer, sizeof(write_buffer));
    if (bytes_written < 0) {
        perror("Failed to write to device");
        close(fd);
        return 1;
    }

    //printf("Wrote %zd bytes to %s at address 0x%lx: 0x%08x\n", bytes_written, FPGA, offset, data);

    // デバイスファイルをクローズ
    close(fd);

    return 0;
}
