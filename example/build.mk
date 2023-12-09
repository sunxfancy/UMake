CXX = clang++
FLEX = win_flex
BISON = win_bison
ARGS = -c -std=c++20 -Isrc -Ibuild
LINK_ARGS = -std=c++20

all: build/main.o build/parser.o build/bison.tab.o build/lex.o build/library.o
	$(CXX) $(LINK_ARGS) $^ -o build/umake

build/lex.cpp: src/lex.ll
	$(FLEX) -o build/lex.cpp src/lex.ll

build/bison.tab.cpp build/bison.tab.hpp: src/bison.yy
	$(BISON) -d -o build/bison.tab.cpp src/bison.yy

build/bison.tab.o: build/bison.tab.cpp src/parser.h 
	$(CXX) $(ARGS) build/bison.tab.cpp -o build/bison.tab.o

build/parser.o: src/parser.cpp build/bison.tab.hpp src/parser.h
	$(CXX) $(ARGS) src/parser.cpp -o build/parser.o 

build/lex.o: build/lex.cpp src/parser.h build/bison.tab.hpp
	$(CXX) $(ARGS) build/lex.cpp -o build/lex.o

build/main.o: src/main.cpp src/parser.h
	$(CXX) $(ARGS) src/main.cpp -o build/main.o

build/library.cpp: etc/library.mk
	echo "const char* templateStr = R\"templateStr(" > build/library.cpp
	cat etc/library.mk >> build/library.cpp
	echo ")templateStr\";" >> build/library.cpp

build/library.o: build/library.cpp
	$(CXX) $(ARGS) build/library.cpp -o build/library.o


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

SHELL = bash

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

ifeq ($(DEBUG),1)
CXX = clang++ 

FLEX = win_flex 

BISON = win_bison 

else
CXX = clang++ 

FLEX = win_flex 

BISON = win_bison 

endif

endif

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

SHELL = bash

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

ifeq ($(DEBUG),1)
CXX = clang++ 

FLEX = win_flex 

BISON = win_bison 

else
CXX = clang++ 

FLEX = win_flex 

BISON = win_bison 

endif

endif
