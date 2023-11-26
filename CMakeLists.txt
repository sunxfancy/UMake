cmake_minimum_required(VERSION 3.15)
project(UMake)

set(CMAKE_CXX_STANDARD 20)

find_package(FLEX REQUIRED)
find_package(BISON REQUIRED)

FLEX_TARGET(Scanner src/lex.ll ${CMAKE_CURRENT_BINARY_DIR}/lex.cpp DEFINES_FILE "${CMAKE_CURRENT_BINARY_DIR}/lex.h")
BISON_TARGET(Parser src/bison.yy ${CMAKE_CURRENT_BINARY_DIR}/bison.cpp DEFINES_FILE "${CMAKE_CURRENT_BINARY_DIR}/bison.tab.hpp")
ADD_FLEX_BISON_DEPENDENCY(Scanner Parser)

include_directories(src ${CMAKE_CURRENT_BINARY_DIR})

add_executable(UMake src/main.cpp src/parser.cpp ${CMAKE_CURRENT_BINARY_DIR}/lex.cpp ${CMAKE_CURRENT_BINARY_DIR}/bison.cpp)

target_link_libraries(UMake zeroerr)