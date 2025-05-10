# コンパイラ
CC = gcc

# コンパイルフラグ
CFLAGS = -Wall

# 共有ライブラリの生成
SHARED_LIB_WRITE = libpcie_write.so
SHARED_LIB_READ = libpcie_read.so

# pyenv
pyenv:
	@python3 -m venv venv
	@echo "Run 'source venv/bin/activate' to activate the virtual environment."

# デフォルトのターゲット: コンパイル
all: $(SHARED_LIB_WRITE) $(SHARED_LIB_READ)

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
	rm -f $(SHARED_LIB_WRITE) $(SHARED_LIB_READ)

# 再コンパイル
rebuild: clean all

# フォルダ内の実行ファイルを全て削除しないようにするための宣言
.PHONY: all clean rebuild debug install uninstall
