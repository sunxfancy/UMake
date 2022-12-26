
# 1. TARGET_PATH  - 这个是存放最终结果，关键数据
# 2. BUILD_PATH   - 真实的构建目录，存放中间数据
# 3. TARGET_PROGRESS_PATH - 存放构建出错时的错误信息，一般是放到 TARGET_PATH/.progress 下, 如果构建中途失败，这些log可以帮助定位问题

# 安全检测
# 1. 检测所依赖的input是否存在, 这个通过output对应生成的target来处理
# 2. 检测输出的output是否存在，如果不存在，立即报错
# 3. 检测每个指令是否执行成功，如果不成功，并且当前指令不能被忽略，则报错
# 4. 完整性检测，每个指令在执行前，先要检测当前指令是否没完全执行完毕，这可以通过查询 TARGET_PATH/.progress 下是否有对应项的进行中标记来判断

# 其他需求
# 1. 彩色输出
# 2. 并行构建
# 3. 支持部分指令远程执行
# 4. 支持部分指令在docker中执行


# 这个脚本的设计目标如下：
# 1. 所有的目标文件都可追踪，可以随时知道进度
# 2. 可以在docker等容器下轻松运行
# 3. 可以被放到cluster上运行
# 4. 可以把单个目标放到远程来运行
# 5. 可以轻松控制各个目标的路径
# 6. 自动发现并include子目录下的Makefile

ifeq (0,1) # The following is the editable source code

#Here is the source code for umake

## ----------------------------------------------------------------------
## This is a help comment. The purpose of this Makefile is to demonstrate
## a simple help mechanism that uses comments defined alongside the rules
## they describe without the need of additional help files or echoing of
## descriptions. Help comments are displayed in the order defined within
## the Makefile.
## ----------------------------------------------------------------------

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

endif # End of the editable source code

#-------------------- Editable Library Code --------------------#


ifeq ($(BUILD_PATH),)

PWD := $(shell pwd)
MAKEFILE_PATH := $(PWD)/Makefile
BUILD_PATH := $(PWD)/build
TMP_PATH := $(PWD)/tmp
COLORFUL := 1
DEBUG := 1

ifeq ($(COLORFUL),1)
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[0;37m
NC := \033[0m
DIM := \033[2m
endif


export

%: 
	@mkdir -p $(BUILD_PATH)
	@$(MAKE) -C $(BUILD_PATH) -f $(MAKEFILE_PATH) $@ 

help:  					  ## Show this help
	@sed -ne 's/^## //p' $(MAKEFILE_LIST)
	@grep -E -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)  %-36s$(NC) %s\n", $$1, $$2}'

gen:
	xmake run -w template umake Makefile

clean:					  ## Clean all
	rm -rf $(BUILD_PATH) $(TMP_PATH)

else


.ONESHELL: 
.NOTINTERMEDIATE: 
.SILENT: 

DEFAULT_PREACTION = @echo -e "$(CYAN)[umake] $@$(NC)"; \
	if [ $(DEBUG) -eq 1 ]; then echo -e "$(DIM)$(MAKEFILE_PATH)$(NC)"; fi
DEFAULT_ACTION = @echo "$A target $T: C = $C V = $V" && mkdir -p $A && touch $@


%: A = $(patsubst %/,%,$(dir $@))
%: T = $(notdir $@)
%: C = $(basename $(T))
%: V = $(suffix $(T))
# %: LTO = $(if $(findstring full,$(C)),full,$(findstring thin,$(C)))

LTO := full thin
FDO := fdoipra fdoipra2 fdoipra3 bfdoipra bfdoipra2 bfdoipra3

HOT_LIST_VAR := 1 3 5 10
RATIO_VAR    := 10 20
VAR := $(foreach k,$(RATIO_VAR),$(foreach j,$(HOT_LIST_VAR),$(j)-$(k)))
COMBINDEX:=$(shell seq 0 $(words $(VAR)))


COMPILER_FLAGS_FDOIPRA:= -mllvm -fdo-ipra -mllvm -fdoipra-both-hot=false
LINKER_FLAGS_FDOIPRA:= -Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-fdoipra-both-hot=false

COMPILER_FLAGS_BFDOIPRA:= -mllvm -fdo-ipra 
LINKER_FLAGS_BFDOIPRA:= -Wl,-mllvm -Wl,-fdo-ipra

COMPILER_FLAGS_CH:= -mllvm -fdoipra-ch=1
LINKER_FLAGS_CH:= -Wl,-mllvm -Wl,-fdoipra-ch=1

COMPILER_FLAGS_HC:= -mllvm -fdoipra-hc=1
LINKER_FLAGS_HC:= -Wl,-mllvm -Wl,-fdoipra-hc=1

COMPILER_FLAGS_FDOIPRA2:= $(COMPILER_FLAGS_FDOIPRA) $(COMPILER_FLAGS_CH)
LINKER_FLAGS_FDOIPRA2:= $(LINKER_FLAGS_FDOIPRA) $(LINKER_FLAGS_CH)

COMPILER_FLAGS_BFDOIPRA2:=  $(COMPILER_FLAGS_BFDOIPRA) $(COMPILER_FLAGS_CH)
LINKER_FLAGS_BFDOIPRA2:= $(LINKER_FLAGS_BFDOIPRA) $(LINKER_FLAGS_CH)

COMPILER_FLAGS_FDOIPRA3:= $(COMPILER_FLAGS_FDOIPRA2) $(COMPILER_FLAGS_HC)
LINKER_FLAGS_FDOIPRA3:= $(LINKER_FLAGS_FDOIPRA2) $(LINKER_FLAGS_HC)

COMPILER_FLAGS_BFDOIPRA3:=  $(COMPILER_FLAGS_BFDOIPRA2) $(COMPILER_FLAGS_HC)
LINKER_FLAGS_BFDOIPRA3:= $(LINKER_FLAGS_BFDOIPRA2) $(LINKER_FLAGS_HC)


common_compiler_flags := $(COMPILER_FLAGS) 
common_linker_flags := $(LINKER_FLAGS)
gen_compiler_flags = -DCMAKE_C_FLAGS=$(1) -DCMAKE_CXX_FLAGS=$(1)
gen_linker_flags   = -DCMAKE_EXE_LINKER_FLAGS=$(1) -DCMAKE_SHARED_LINKER_FLAGS=$(1) -DCMAKE_MODULE_LINKER_FLAGS=$(1)
additional_compiler_flags = 
additional_linker_flags =
additional_original_flags = 


define check_file_exist
	@if [ ! -f $1 ]; then echo "Error: $1 does not exist"; exit 1; fi
endef 

define check_dir_exist
	@if [ ! -d $1 ]; then echo "Error: $1 does not exist"; exit 1; fi
endef

define make_sure_parent_dir_exist
	@mkdir -p $(abspath $1/..)
endef 


#-------------------- DO NOT EDIT BELOW THIS LINE --------------------#

ifeq ($(DEBUG),1)
.PRECIOUS: hotlist/% perf/%


define GENERATE_1
build/pgo-$(LTO_IT): profdata $(TMP_PATH)/source/.complete
	$$(DEFAULT_PREACTION)
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(eval $(call GENERATE_1)))

define GENERATE_2
build/pgo-$(LTO_IT)-$(FDO_IT): hotlist/pgo-$(LTO_IT) $(TMP_PATH)/source/.complete
	$$(DEFAULT_PREACTION)
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(foreach FDO_IT, $(FDO),$(eval $(call GENERATE_2))))

define GENERATE_3
build/pgo-$(LTO_IT)-$(FDO_IT).$(VAR_IT): build/pgo-$(LTO_IT)-$(FDO_IT)
	$$(DEFAULT_PREACTION)
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(foreach FDO_IT, $(FDO),$(foreach VAR_IT, $(VAR),$(eval $(call GENERATE_3)))))

build/instrumented: $(TMP_PATH)/source/.complete
	$(DEFAULT_PREACTION)
	$(DEFAULT_ACTION)


source:
	$(DEFAULT_PREACTION)
	$(call make_sure_parent_dir_exist,source.dir/1.zip)
	$(call make_sure_parent_dir_exist,source.dir/2.zip)
	touch source.dir/1.zip
	touch source.dir/2.zip
	$(call check_file_exist,source.dir/1.zip)
	$(call check_file_exist,source.dir/2.zip)
	$(DEFAULT_ACTION)


$(TMP_PATH)/source/.complete: source
	$(DEFAULT_PREACTION)
	mkdir -p $(TMP_PATH)
	cd $(TMP_PATH)
	$(call check_file_exist,$(BUILD_PATH)/source.dir/1.zip)
	$(call make_sure_parent_dir_exist,$(TMP_PATH)/source)
	mkdir -p $(TMP_PATH)/source
	$(call check_dir_exist,$(TMP_PATH)/source)
	$(DEFAULT_ACTION)


hotlist/%: perf/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$(BUILD_PATH)/$< )
	$(call make_sure_parent_dir_exist,$@)
	touch $@
	$(call check_file_exist,$@)
	$(DEFAULT_ACTION)


profdata: build/instrumented
	$(DEFAULT_PREACTION)
	$(call make_sure_parent_dir_exist,$@)
	touch $@
	$(call check_file_exist,$@)
	$(DEFAULT_ACTION)


perf/%: build/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$C/bin/clang$V)
	$(call make_sure_parent_dir_exist,$@)
	touch $@
	$(call check_file_exist,$@)
	$(DEFAULT_ACTION)


bench/%: build/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$C/bin/clang$V)
	$(call make_sure_parent_dir_exist,$@)
	touch $@
	$(call check_file_exist,$@)
	$(DEFAULT_ACTION)


else
.PRECIOUS: hotlist/% perf/%


define GENERATE_4
build/pgo-$(LTO_IT): profdata $(TMP_PATH)/source/.complete
	$$(DEFAULT_PREACTION)
	mkdir -p $$C/bin && touch $$C/bin/clang
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(eval $(call GENERATE_4)))

define GENERATE_5
build/pgo-$(LTO_IT)-$(FDO_IT): hotlist/pgo-$(LTO_IT) $(TMP_PATH)/source/.complete
	$$(DEFAULT_PREACTION)
	mkdir -p $$C/bin && touch $$C/bin/clang 
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(foreach FDO_IT, $(FDO),$(eval $(call GENERATE_5))))

define GENERATE_6
build/pgo-$(LTO_IT)-$(FDO_IT).$(VAR_IT): build/pgo-$(LTO_IT)-$(FDO_IT)
	$$(DEFAULT_PREACTION)
	touch $$C/bin/clang$$V
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(foreach FDO_IT, $(FDO),$(foreach VAR_IT, $(VAR),$(eval $(call GENERATE_6)))))

build/instrumented: $(TMP_PATH)/source/.complete
	$(DEFAULT_PREACTION)
	mkdir -p $C/bin && touch $C/bin/clang
	$(DEFAULT_ACTION)


source:
	$(DEFAULT_PREACTION)
	$(call make_sure_parent_dir_exist,source.dir/1.zip)
	$(call make_sure_parent_dir_exist,source.dir/2.zip)
	wget google.com -O source.dir/1.zip
	wget github.com -O source.dir/2.zip
	$(call check_file_exist,source.dir/1.zip)
	$(call check_file_exist,source.dir/2.zip)
	$(DEFAULT_ACTION)


$(TMP_PATH)/source/.complete: source
	$(DEFAULT_PREACTION)
	mkdir -p $(TMP_PATH)
	cd $(TMP_PATH)
	$(call check_file_exist,$(BUILD_PATH)/source.dir/1.zip)
	$(call make_sure_parent_dir_exist,$(TMP_PATH)/source)
	mkdir -p  $(TMP_PATH)/source && cat $(BUILD_PATH)/source.dir/1.zip > $(TMP_PATH)/source/1.c
	$(call check_dir_exist,$(TMP_PATH)/source)
	$(DEFAULT_ACTION)


hotlist/%: perf/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$(BUILD_PATH)/$< )
	$(call make_sure_parent_dir_exist,$@)
	mkdir -p hotlist
	cat $(BUILD_PATH)/$<  | awk '{print "hotlist gen from:\n $$1"}' > $@
	$(call check_file_exist,$@)
	$(DEFAULT_ACTION)


profdata: build/instrumented
	$(DEFAULT_PREACTION)
	$(call make_sure_parent_dir_exist,$@)
	echo "prof data gen" > $@
	$(call check_file_exist,$@)
	$(DEFAULT_ACTION)


perf/%: build/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$C/bin/clang$V)
	$(call make_sure_parent_dir_exist,$@)
	mkdir -p perf
	cat $C/bin/clang$V > $@
	$(call check_file_exist,$@)
	$(DEFAULT_ACTION)


bench/%: build/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$C/bin/clang$V)
	$(call make_sure_parent_dir_exist,$@)
	mkdir -p bench
	cat $C/bin/clang$V > $@
	$(call check_file_exist,$@)
	$(DEFAULT_ACTION)


endif

endif
