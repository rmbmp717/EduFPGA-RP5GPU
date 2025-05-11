#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#define DEVICE "/dev/EduGPU_pcie_driver0"
#define FPGA "FPGA"

int read_from_device(unsigned int *data, off_t offset) {
    int fd;
    ssize_t bytes_read;
    unsigned char read_buffer[4];  // 4バイトのバッファ

    // アドレスが4バイトごとかを確認
    if (offset % 4 != 0) {
        fprintf(stderr, "Error: Address 0x%lx is not 4-byte aligned.\n", offset);
        return 1;
    }

    // デバイスファイルをリードオンリーでオープン
    fd = open(DEVICE, O_RDONLY);
    if (fd < 0) {
        perror("Failed to open device for reading");
        return 1;
    }

    // オフセットを設定
    if (lseek(fd, offset, SEEK_SET) == (off_t)-1) {
        perror("Failed to set offset for reading");
        close(fd);
        return 1;
    }

    // デバイスからデータを読み取る（4バイト）
    bytes_read = read(fd, read_buffer, sizeof(read_buffer));
    if (bytes_read < 0) {
        perror("Failed to read from device");
        close(fd);
        return 1;
    }

    // 読み取ったデータを1つの32ビットの整数に結合
    *data = (read_buffer[0] << 24) | 
            (read_buffer[1] << 16) | 
            (read_buffer[2] << 8)  | 
            (read_buffer[3]);

    //printf("Read %zd bytes from %s at address 0x%lx: 0x%08x\n", bytes_read, FPGA, offset, *data);

    // デバイスファイルをクローズ
    close(fd);

    return 0;
}