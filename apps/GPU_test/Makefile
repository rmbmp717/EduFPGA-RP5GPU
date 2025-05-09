# コンパイラ
CC = gcc

# コンパイルフラグ
CFLAGS = -Wall

# ターゲット実行ファイル名
TARGETS = read_pcie write_pcie reg_set
TARGETS += write_read_test

# ソースファイル
SRCS = read_pcie.c write_pcie.c reg_set.c
SRCS += write_read_test.c

# オブジェクトファイル
OBJS = $(SRCS:.c=.o)

# 共有ライブラリの生成
SHARED_LIB_WRITE = libpcie_write.so
SHARED_LIB_READ = libpcie_read.so

# デフォルトのターゲット: コンパイル
all: $(TARGETS) $(SHARED_LIB_WRITE) $(SHARED_LIB_READ)

# 実行ファイルの生成ルール
read_pcie: read_pcie.o
	$(CC) $(CFLAGS) -o $@ $^

write_pcie: write_pcie.o
	$(CC) $(CFLAGS) -o $@ $^

reg_set: reg_set.o
	$(CC) $(CFLAGS) -o $@ $^

write_read_test: write_read_test.o
	$(CC) $(CFLAGS) -o $@ $^

# 共有ライブラリの生成ルール (write用)
$(SHARED_LIB_WRITE): func_write_pcie.c
	$(CC) -shared -o $(SHARED_LIB_WRITE) -fPIC func_write_pcie.c

# 共有ライブラリの生成ルール (read用)
$(SHARED_LIB_READ): func_read_pcie.c
	$(CC) -shared -o $(SHARED_LIB_READ) -fPIC func_read_pcie.c

# コンパイルルール: ソースファイルをオブジェクトファイルに
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# デバッグ用ビルド
debug: CFLAGS += -g
debug: rebuild

# 実行ファイルをクリーンアップ
clean:
	rm -f $(OBJS) $(TARGETS) $(SHARED_LIB_WRITE) $(SHARED_LIB_READ)

# 再コンパイル
rebuild: clean all

# インストール
install: $(TARGETS)
	install -m 0755 $(TARGETS) /usr/local/bin

# アンインストール
uninstall:
	rm -f $(addprefix /usr/local/bin/, $(TARGETS))

# フォルダ内の実行ファイルを全て削除しないようにするための宣言
.PHONY: all clean rebuild debug install uninstall
