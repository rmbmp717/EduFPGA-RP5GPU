#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#define DEVICE "/dev/EduGraphics_pcie_driver0"
#define WRITE_BUFFER_SIZE 1
#define READ_BUFFER_SIZE 4
#define NUM_ITERATIONS 1000

int main() {
    int fd_write, fd_read;
    unsigned char write_buffer[WRITE_BUFFER_SIZE];
    char read_buffer[READ_BUFFER_SIZE];
    ssize_t bytes_written, bytes_read;
    off_t target_address = 0x0004;  // 書き込み、読み込み先のオフセット

    // デバイスファイルをライトオンリーでオープン
    fd_write = open(DEVICE, O_WRONLY);
    if (fd_write < 0) {
        perror("Failed to open device for writing");
        return 1;
    }

    // デバイスファイルをリードオンリーでオープン
    fd_read = open(DEVICE, O_RDONLY);
    if (fd_read < 0) {
        perror("Failed to open device for reading");
        close(fd_write);
        return 1;
    }

    // 1000回ライト、リードを繰り返す
    for (int iteration = 0; iteration < NUM_ITERATIONS; iteration++) {
        // 書き込みデータを設定
        write_buffer[0] = (unsigned char)((iteration % 256) + 1);  // 0x01 ~ 0xFF

        // オフセットを設定（ライト側）
        if (lseek(fd_write, target_address, SEEK_SET) == (off_t)-1) {
            perror("Failed to set offset for writing");
            close(fd_write);
            close(fd_read);
            return 1;
        }

        // デバイスにデータを書き込む
        bytes_written = write(fd_write, write_buffer, sizeof(write_buffer));
        if (bytes_written < 0) {
            perror("Failed to write to device");
            close(fd_write);
            close(fd_read);
            return 1;
        }

        printf("Iteration %d: Wrote %zd bytes to %s at address 0x%lx: 0x%02x\n", 
               iteration + 1, bytes_written, DEVICE, target_address, write_buffer[0]);

        // オフセットを設定（リード側）
        if (lseek(fd_read, target_address, SEEK_SET) == (off_t)-1) {
            perror("Failed to set offset for reading");
            close(fd_write);
            close(fd_read);
            return 1;
        }

        // デバイスからデータを読み取る
        bytes_read = read(fd_read, read_buffer, sizeof(read_buffer));
        if (bytes_read < 0) {
            perror("Failed to read from device");
            close(fd_write);
            close(fd_read);
            return 1;
        }

        // 読み取ったデータを表示
        printf("Read %zd bytes from %s at address 0x%lx: ", bytes_read, DEVICE, target_address);
        for (int i = 0; i < bytes_read; i++) {
            printf("%02x ", read_buffer[i] & 0xFF);  // 各バイトを16進数で表示
        }
        printf("\n");

        // 1000回に到達したら終了
        if (iteration + 1 == NUM_ITERATIONS) {
            printf("Completed %d iterations of read/write\n", NUM_ITERATIONS);
        }
    }

    // デバイスファイルをクローズ
    close(fd_write);
    close(fd_read);

    return 0;
}
