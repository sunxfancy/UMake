# UMake

[![English Readme](https://img.shields.io/badge/English-Readme-blue)](./README.en.md)

这是一个Makefile的自动生成工具，用来创建一些较为复杂的自动化测试脚本，主要特性：

1. 支持自动生成基础的Makefile框架，以及导入自己编写的Makefile框架
2. 支持进行安全检测，每个步骤结束后，对生成的文件，文件夹都会进行检测，来确保确实生成成功，否则脚本就会尽早报错，避免一些传参时，文件在找不到时工具却没有报错的情况。
3. 对脚本执行是否成功进行检测，如果遇到执行失败的命令会中断并保留现场方便调试
4. 支持完整性检测，每个步骤只有所有的步骤全部完成后，最后的标记才会标记当前步骤已完成
5. 自动对一系列可能情况生成target，避免模式匹配中匹配不到的问题
6. 自动确保cd到的目录，目标文件生成目录均存在

新定义的语法：
```
target-%(ARRAY)-%(CASE2): %(ARRAY)-%(CASE2)   这种可以一次性定义一组target
```

- `<FO:file/path>` 可以用来标记一个输出文件，这样系统会自动加入两个检测代码，首先确保输出目录存在，避免目录错误，其次会在执行后进行检测，确保输出文件真的存在
- `<DO:...>` 目录输出
- `<FI:...>` 文件输入
- `<DI:...>` 目录输入

示例文法：

```makefile
help:     ## Show this help.
.PRECIOUS: hotlist/% perf/%

build/pgo-%(LTO): profdata $(TMP_PATH)/source/   ## Build PGO Build with FullLTO
	mkdir -p $C/bin && touch $C/bin/clang

build/pgo-%(LTO)-%(FDO): hotlist/pgo-%(LTO) $(TMP_PATH)/source/  ## Build PGO-LTO FDOIPRA versions
	mkdir -p $C/bin && touch $C/bin/clang 

build/pgo-%(LTO)-%(FDO).%(VAR): build/pgo-%(LTO)-%(FDO)  ## Build FDOIPRA variant versions
	touch $C/bin/clang$V

build/instrumented: $(TMP_PATH)/source/   ## Build instrumented binary
	mkdir -p $C/bin && touch $C/bin/clang

source:  					## Download source code
	wget google.com -O <FO:source.dir/1.zip>
	wget github.com -O <FO:source.dir/2.zip>

$(TMP_PATH)/source/: source   
	cd $(TMP_PATH)
	mkdir -p  <DO:$(TMP_PATH)/source> && cat <FI:$(BUILD_PATH)/source.dir/1.zip> > $(TMP_PATH)/source/1.c

hotlist/%: perf/%  			## Generate hotlist
	mkdir -p hotlist
	cat <FI:$(BUILD_PATH)/$< > | awk '{print "hotlist gen from:\n $$1"}' > <FO:$@>

profdata: build/instrumented  ## Generate profdata
	echo "prof data gen" > <FO:$@>

perf/%: build/%              ## Run perf record
	mkdir -p perf
	cat <FI:$C/bin/clang$V> > <FO:$@>

bench/%: build/%             ## Run perf stat
	mkdir -p bench
	cat <FI:$C/bin/clang$V> > <FO:$@>
```

## 如何使用

### 安装

使用 `wget` 下载 `get.sh` 脚本执行
```bash
wget https://fastly.jsdelivr.net/gh/sunxfancy/UMake@master/etc/get.sh -O - | bash
```

使用 `curl` 下载 `get.sh` 脚本执行
```bash
curl -fsSL https://fastly.jsdelivr.net/gh/sunxfancy/UMake@master/etc/get.sh | bash
```

使用 `Powershell` 下载 `get.ps1` 脚本执行
```powershell
Invoke-Expression (Invoke-WebRequest -Uri https://fastly.jsdelivr.net/gh/sunxfancy/UMake@master/etc/get.ps1 -UseBasicParsing).Content
```
