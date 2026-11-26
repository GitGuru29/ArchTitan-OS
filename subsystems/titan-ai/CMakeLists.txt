cmake_minimum_required(VERSION 3.16)
project(titan_ai LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBCURL REQUIRED libcurl)
pkg_check_modules(OPENSSL REQUIRED openssl)

add_executable(titan-ai src/titan_ai.cpp)
target_include_directories(titan-ai PRIVATE ${LIBCURL_INCLUDE_DIRS} ${OPENSSL_INCLUDE_DIRS})
target_link_directories(titan-ai PRIVATE ${LIBCURL_LIBRARY_DIRS} ${OPENSSL_LIBRARY_DIRS})
target_link_libraries(titan-ai PRIVATE ${LIBCURL_LIBRARIES} ${OPENSSL_LIBRARIES})
target_compile_options(titan-ai PRIVATE -O2 -Wall -Wextra)
