#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <time.h>

#define DEVICE_FILE "/dev/EduGPU_pcie_driver0"  // デバイスファイルのパス

// ioctlコマンドの定義（ドライバと一致させる）
#define EDU_DMA_START       _IO('E', 1)
#define EDU_DMA_WAIT        _IO('E', 2)
#define EDU_SET_MEM_SELECT  _IOW('E', 3, int)
#define DMA_TIMEOUT_SECONDS 5  // DMAのタイムアウト時間（秒）

int main() {
    int fd;
    size_t dma_buffer_size = 256 * 1024;
    void *dma_buffer;
    int mem_select = 1;  // DMAバッファを選択するために1を設定

    // デバイスファイルを開く
    fd = open(DEVICE_FILE, O_RDWR);
    if (fd < 0) {
        perror("デバイスファイルを開けませんでした");
        return -1;
    }

    // mem_selectを1に設定してDMAバッファをマッピングするように指示
    if (ioctl(fd, EDU_SET_MEM_SELECT, &mem_select) < 0) {
        perror("mem_selectの設定に失敗しました");
        close(fd);
        return -1;
    }

    // DMAバッファをマッピング
    dma_buffer = mmap(NULL, dma_buffer_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (dma_buffer == MAP_FAILED) {
        perror("DMAバッファのマッピングに失敗しました");
        close(fd);
        return -1;
    }

    // DMAバッファにデータを書き込む（例として0xAAのパターンで埋める）
    memset(dma_buffer, 0xAA, dma_buffer_size);

    // DMA転送を開始
    if (ioctl(fd, EDU_DMA_START) < 0) {
        perror("DMA転送の開始に失敗しました");
        munmap(dma_buffer, dma_buffer_size);
        close(fd);
        return -1;
    }

    // DMA転送の完了をタイムアウト付きで待機
    struct timespec start, now;
    clock_gettime(CLOCK_MONOTONIC, &start);
    int result;

    while (1) {
        result = ioctl(fd, EDU_DMA_WAIT);
        if (result == 0) {
            // DMA転送が正常に完了
            break;
        } else if (errno == EINTR) {
            // シグナルで中断された場合は再試行
            continue;
        } else {
            // 他のエラーが発生した場合
            perror("DMA転送の完了待機に失敗しました");
            munmap(dma_buffer, dma_buffer_size);
            close(fd);
            return -1;
        }

        // タイムアウトのチェック
        clock_gettime(CLOCK_MONOTONIC, &now);
        if ((now.tv_sec - start.tv_sec) > DMA_TIMEOUT_SECONDS) {
            fprintf(stderr, "DMA転送がタイムアウトしました\n");
            munmap(dma_buffer, dma_buffer_size);
            close(fd);
            return -1;
        }
    }

    // DMAバッファからデータを読み取る（例として最初の10バイトを表示）
    uint8_t *buffer = (uint8_t *)dma_buffer;
    printf("DMAバッファの内容（先頭10バイト）:\n");
    for (size_t i = 0; i < 10; i++) {
        printf("0x%02X ", buffer[i]);
    }
    printf("\n");

    // リソースを解放
    munmap(dma_buffer, dma_buffer_size);
    close(fd);

    return 0;
}