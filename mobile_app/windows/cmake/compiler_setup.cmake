# cmake/compiler_setup.cmake
# Setup Visual Studio generator for Flutter on Windows

# This file ensures we use the correct Visual Studio generator
if(NOT DEFINED CMAKE_GENERATOR)
  if(EXISTS "C:\\Program Files\\Microsoft Visual Studio\\18")
    set(CMAKE_GENERATOR "Visual Studio 18 2024" CACHE STRING "CMake generator")
  elseif(EXISTS "C:\\Program Files\\Microsoft Visual Studio\\17")
    set(CMAKE_GENERATOR "Visual Studio 17 2022" CACHE STRING "CMake generator")
  else()
    # Default to Ninja if available
    find_program(NINJA_EXECUTABLE ninja)
    if(NINJA_EXECUTABLE)
      set(CMAKE_GENERATOR "Ninja" CACHE STRING "CMake generator")
    else()
      message(FATAL_ERROR "No suitable CMake generator found. Install Visual Studio 2026 or Ninja.")
    endif()
  endif()
endif()

message(STATUS "Using CMake generator: ${CMAKE_GENERATOR}")
