# UMake

[![中文Readme](https://img.shields.io/badge/%E4%B8%AD%E6%96%87-Readme-blue)](./README.md)

UMake is a for generating Makefile automatically, it can be used to create some more complex automated test scripts. The main features are as follows:

1. Support to automatically generate the basic Makefile framework, and import the other Makefile framework written by yourself
2. Support safety detection, after each step, the generated files and folders will be detected to ensure that they are really generated successfully, otherwise the script will report an error as soon as possible, avoiding some situations where the file cannot be found when passing parameters, but the tool does not report an error.
3. Check whether the script execution is successful. If a failed command is encountered, it will be interrupted and the scene will be retained for easy debugging
4. Support integrity detection, each step will only be marked as completed after all steps are completed
5. Automatically generate targets for a series of possible situations to avoid the problem that the pattern matching cannot be matched
6. Automatically ensure that the directory cd to and the target file generation directory exist

## Why make a Makefile generator?

Makefile is a powerful tool and widely used in the industry. For many production environment, it's one of the standard toolchain already deployed. Other binary may be not available or not allowed to use, but Makefile is always there. So using Makefile is still a easy way to create a script for automation.


## The syntax of the UMake

Newly defined syntax:
```
target-%(ARRAY)-%(CASE2): %(ARRAY)-%(CASE2)   target
```

- `<FO:file/path>` used to mark a file output, so the tool will automatically add two lines of detection code, first ensure that the output directory exists, to avoid directory errors, and then check after execution to ensure that the output file really exists
- `<DO:...>` output directory
- `<FI:...>` file input
- `<DI:...>` directory input

An example：

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
