# コンパイラ
CC = gcc

# コンパイルフラグ
CFLAGS = -Wall

# ターゲット実行ファイル名
TARGETS = read_pcie write_pcie reg_set dma_write_pcie

# ソースファイル
SRCS = read_pcie.c write_pcie.c reg_set.c dma_write_pcie.c

# オブジェクトファイル
OBJS = $(SRCS:.c=.o)

# デフォルトのターゲット: コンパイル
all: $(TARGETS)

# 実行ファイルの生成ルール
read_pcie: read_pcie.o
	$(CC) $(CFLAGS) -o $@ $^

write_pcie: write_pcie.o
	$(CC) $(CFLAGS) -o $@ $^

reg_set: reg_set.o
	$(CC) $(CFLAGS) -o $@ $^

# コンパイルルール: ソースファイルをオブジェクトファイルに
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# 実行ファイルをクリーンアップ
clean:
	rm -f $(OBJS) $(TARGETS)

# 再コンパイル
rebuild: clean all

# フォルダ内の実行ファイルを全て削除しないようにするための宣言
.PHONY: all clean rebuild