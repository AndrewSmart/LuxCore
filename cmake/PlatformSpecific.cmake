################################################################################
# Copyright 1998-2018 by authors (see AUTHORS.txt)
#
#   This file is part of LuxCoreRender.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

# Use relative paths
# This is mostly to reduce path size for command-line limits on windows
if(WIN32)
  # This seems to break Xcode projects so definitely don't enable on Apple builds
  set(CMAKE_USE_RELATIVE_PATHS true)
  set(CMAKE_SUPPRESS_REGENERATION true)
endif(WIN32)

include(AdjustToolFlags)

###########################################################################
#
# Compiler Flags
#
###########################################################################

###########################################################################
#
# VisualStudio
#
###########################################################################

IF(MSVC)
	message(STATUS "MSVC")

	# Change warning level to something saner
	# Force to always compile with W0
	if(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
		string(REGEX REPLACE "/W[0-4]" "/W0" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
	else()
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W0")
	endif()

	# Minimizes Windows header files
	ADD_DEFINITIONS(-DWIN32_LEAN_AND_MEAN)
	# Do not define MIN and MAX macros
	ADD_DEFINITIONS(-DNOMINMAX)
	# Do not warn about standard but insecure functions
	ADD_DEFINITIONS(-D_CRT_SECURE_NO_WARNINGS -D_SCL_SECURE_NO_WARNINGS)
	# Enable Unicode
	ADD_DEFINITIONS(-D_UNICODE)
	# Enable SSE2/SSE/MMX
	ADD_DEFINITIONS(-D__SSE2__ -D__SSE__ -D__MMX__)

	SET(FLEX_FLAGS "--wincompat")

	# Base settings

	# Disable incremental linking, because LTCG is currently triggered by
	# linking with a pre-built lib and then we'll see a warning:
	AdjustToolFlags(
				CMAKE_EXE_LINKER_FLAGS_DEBUG
				CMAKE_MODULE_LINKER_FLAGS_DEBUG
				CMAKE_SHARED_LINKER_FLAGS_DEBUG
			ADDITIONS "/INCREMENTAL:NO"
			REMOVALS "/INCREMENTAL(:YES|:NO)?")

	# Always link with the release runtime DLL:
	AdjustToolFlags(CMAKE_C_FLAGS CMAKE_CXX_FLAGS "/MD")
	AdjustToolFlags(
				CMAKE_C_FLAGS_DEBUG
				CMAKE_C_FLAGS_RELEASE
				CMAKE_C_FLAGS_MINSIZEREL
				CMAKE_C_FLAGS_RELWITHDEBINFO
				CMAKE_CXX_FLAGS_DEBUG
				CMAKE_CXX_FLAGS_RELEASE
				CMAKE_CXX_FLAGS_MINSIZEREL
				CMAKE_CXX_FLAGS_RELWITHDEBINFO
			REMOVALS "/MDd? /MTd? /RTC1 /D_DEBUG")

	# Optimization options:

	# Whole Program Opt. gui display fixed in cmake 2.8.5
	# See http://public.kitware.com/Bug/view.php?id=6794
	# /GL will be used to build the code but the selection is not displayed in the menu
	set(MSVC_RELEASE_COMPILER_FLAGS "/WX- /MP /Ox /Ob2 /Oi /Oy /GT /GL /Gm- /EHsc /MD /GS /fp:precise /Zc:wchar_t /Zc:forScope /GR /Gd /TP /GL /GF /Ot")

	#set(MSVC_RELEASE_LINKER_FLAGS "/LTCG /OPT:REF /OPT:ICF")
	#set(MSVC_RELEASE_WITH_DEBUG_LINKER_FLAGS "/DEBUG")
	# currently not in release version but should be soon - in meantime linker will inform you about switching this flag automatically because of /GL
	#set(MSVC_RELEASE_LINKER_FLAGS "/LTCG /OPT:REF /OPT:ICF")
	set(MSVC_RELEASE_LINKER_FLAGS "/INCREMENTAL:NO /LTCG")

	IF(MSVC90)
		message(STATUS "Version 9")
	ENDIF(MSVC90)

	IF(MSVC10)
		message(STATUS "Version 10")
		list(APPEND MSVC_RELEASE_COMPILER_FLAGS "/arch:SSE2 /openmp")
	ENDIF(MSVC10)

	IF(MSVC12 OR MSVC14)
		message(STATUS "MSVC Version: " ${MSVC_VERSION} )

		list(APPEND MSVC_RELEASE_COMPILER_FLAGS "/openmp /Qfast_transcendentals /wd\"4244\" /wd\"4756\" /wd\"4267\" /wd\"4056\" /wd\"4305\" /wd\"4800\"")

		# Use multiple processors in debug mode, for faster rebuild:
		AdjustToolFlags(
				CMAKE_C_FLAGS_DEBUG CMAKE_CXX_FLAGS_DEBUG ADDITIONS "/MP")
	ENDIF(MSVC12 OR MSVC14)

	AdjustToolFlags(
				CMAKE_C_FLAGS_RELEASE
				CMAKE_CXX_FLAGS_RELEASE
			ADDITIONS ${MSVC_RELEASE_COMPILER_FLAGS})

	set(MSVC_RELEASE_WITH_DEBUG_COMPILER_FLAGS ${MSVC_RELEASE_COMPILER_FLAGS} "/Zi")
	AdjustToolFlags(CMAKE_C_FLAGS_RELWITHDEBINFO CMAKE_CXX_FLAGS_RELWITHDEBINFO
			ADDITIONS ${MSVC_RELEASE_WITH_DEBUG_COMPILER_FLAGS})

	AdjustToolFlags(
				CMAKE_EXE_LINKER_FLAGS_RELEASE
				CMAKE_STATIC_LINKER_FLAGS_RELEASE
				CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO
				CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO
			ADDITIONS ${MSVC_RELEASE_LINKER_FLAGS}
			REMOVALS "/INCREMENTAL(:YES|:NO)?")
ENDIF(MSVC)

###########################################################################
#
# Apple
#
###########################################################################

# Setting Universal Binary Properties, only for Mac OS X
#  generate with xcode/crosscompile, setting: ( darwin - 10.7 - gcc - g++ - MacOSX10.7.sdk - Find from root, then native system )
IF(APPLE)
  CMAKE_MINIMUM_REQUIRED(VERSION 3.12) #Required for FindBoost 1.67.0

	########## OS and hardware detection ###########

	execute_process(COMMAND uname -r OUTPUT_VARIABLE MAC_SYS) # check for actual system-version

  if(${MAC_SYS} MATCHES 17)
    set(OSX_SYSTEM 10.13)
  elseif(${MAC_SYS} MATCHES 16)
    set(OSX_SYSTEM 10.12)
  elseif(${MAC_SYS} MATCHES 15)
    set(OSX_SYSTEM 10.11)
	elseif(${MAC_SYS} MATCHES 14)
		set(OSX_SYSTEM 10.10)
	elseif(${MAC_SYS} MATCHES 13)
		set(OSX_SYSTEM 10.9)
	elseif(${MAC_SYS} MATCHES 12)
		set(OSX_SYSTEM 10.8)
	elseif(${MAC_SYS} MATCHES 11)
		set(OSX_SYSTEM 10.7)
	elseif(${MAC_SYS} MATCHES 10)
		set(OSX_SYSTEM 10.6)
	else()
		set(OSX_SYSTEM unsupported)
	endif()

  if(14 LESS ${MAC_SYS})
    set(QT_BINARY_DIR /usr/local/bin) # workaround for the locked /usr/bin install Qt ti /usr/local !
  endif()

	if(NOT ${CMAKE_GENERATOR} MATCHES "Xcode") # unix makefile generator does not fill XCODE_VERSION var !
		execute_process(COMMAND xcodebuild -version OUTPUT_VARIABLE XCODE_VERS_BUILDNR )
		STRING(SUBSTRING ${XCODE_VERS_BUILDNR} 6 3 XCODE_VERSION) # truncate away build-nr
	endif()

	set(CMAKE_OSX_DEPLOYMENT_TARGET 10.12) # keep this @ 10.12 to achieve bw-compatibility by weak-linking !

    if(${CMAKE_GENERATOR} MATCHES "Xcode" AND ${XCODE_VERSION} VERSION_LESS 5.0)
        if(CMAKE_VERSION VERSION_LESS 2.8.1)
            SET(CMAKE_OSX_ARCHITECTURES i386;x86_64)
        else(CMAKE_VERSION VERSION_LESS 2.8.1)
            SET(CMAKE_XCODE_ATTRIBUTE_ARCHS i386\ x86_64)
        endif(CMAKE_VERSION VERSION_LESS 2.8.1)
    else()
        SET(CMAKE_XCODE_ATTRIBUTE_ARCHS $(NATIVE_ARCH_ACTUAL))
    endif()

	if(${XCODE_VERSION} VERSION_LESS 4.3)
		SET(CMAKE_OSX_SYSROOT /Developer/SDKs/MacOSX${OSX_SYSTEM}.sdk)
	else()
		SET(CMAKE_OSX_SYSROOT /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${OSX_SYSTEM}.sdk)
        set(CMAKE_XCODE_ATTRIBUTE_SDKROOT macosx) # to silence sdk not found warning, just overrides CMAKE_OSX_SYSROOT, gets alway latest available
	endif()

    # set a precedence of sdk path over all other default search pathes
    SET(CMAKE_FIND_ROOT_PATH ${CMAKE_OSX_SYSROOT})

	### options
	option(OSX_UPDATE_LUXRAYS_REPO "Copy LuxRays dependencies over to macos repo after compile" TRUE)
	option(OSX_BUILD_DEMOS "Compile benchsimple, luxcoredemo, luxcorescenedemo and luxcoreimplserializationdemo" FALSE)

	set(LUXRAYS_NO_DEFAULT_CONFIG true)
  SET(LUXRAYS_CUSTOM_CONFIG "Config_OSX" CACHE STRING "")

	if(NOT ${CMAKE_GENERATOR} MATCHES "Xcode") # will be set later in XCode
		#SET(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE STRING "assure config" FORCE)
		# Setup binaries output directory in Xcode manner
		SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE} CACHE PATH "per configuration" FORCE)
		SET(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib/${CMAKE_BUILD_TYPE} CACHE PATH "per configuration" FORCE)
	else() # replace CMAKE_BUILD_TYPE with XCode env var $(CONFIGURATION) globally
		SET(CMAKE_BUILD_TYPE "$(CONFIGURATION)" )
	endif()
        SET(CMAKE_BUILD_RPATH "@loader_path")
        SET(CMAKE_INSTALL_RPATH "@loader_path")
	#### OSX-flags by jensverwiebe
	ADD_DEFINITIONS(-Wall -DHAVE_PTHREAD_H) # global compile definitions
	ADD_DEFINITIONS(-fvisibility=hidden -fvisibility-inlines-hidden)
	ADD_DEFINITIONS(-Wno-unused-local-typedef -Wno-unused-variable) # silence boost __attribute__((unused)) bug
	set(OSX_FLAGS_RELEASE "-ftree-vectorize -msse -msse2 -msse3 -mssse3") # only additional flags
	set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${OSX_FLAGS_RELEASE}") # cmake emits "-O3 -DNDEBUG" for Release by default, "-O0 -g" for Debug
	set(CMAKE_CXX_FLAGS_RELEASE "-std=c++11 ${CMAKE_CXX_FLAGS_RELEASE} ${OSX_FLAGS_RELEASE}")
	set(CMAKE_EXE_LINKER_FLAGS "-Wl,-unexported_symbols_list -Wl,\"${CMAKE_SOURCE_DIR}/cmake/exportmaps/unexported_symbols.map\"")
	set(CMAKE_MODULE_LINKER_FLAGS "-Wl,-unexported_symbols_list -Wl,\"${CMAKE_SOURCE_DIR}/cmake/exportmaps/unexported_symbols.map\"")

	SET(CMAKE_XCODE_ATTRIBUTE_DEPLOYMENT_POSTPROCESSING YES) # strip symbols in whole project, disabled in pylux target
	if(${CMAKE_C_COMPILER_ID} MATCHES "Clang" AND NOT ${CMAKE_C_COMPILER_VERSION} LESS 6.0) # Apple LLVM version 6.0 (clang-600.0.54) (based on LLVM 3.5svn)
		SET(CMAKE_XCODE_ATTRIBUTE_DEAD_CODE_STRIPPING YES) #  -dead_strip, disabled for clang 3.4 lto bug
	endif()
	if(NOT ${XCODE_VERSION} VERSION_LESS 5.1) # older xcode versions show problems with LTO
		SET(CMAKE_XCODE_ATTRIBUTE_LLVM_LTO YES)
	endif()

	MESSAGE(STATUS "")
	MESSAGE(STATUS "################ GENERATED XCODE PROJECT INFORMATION ################")
	MESSAGE(STATUS "")
    MESSAGE(STATUS "Detected system-version: " ${OSX_SYSTEM})
	MESSAGE(STATUS "OSX_DEPLOYMENT_TARGET : " ${CMAKE_OSX_DEPLOYMENT_TARGET})
	IF(CMAKE_VERSION VERSION_LESS 2.8.1)
		MESSAGE(STATUS "Setting CMAKE_OSX_ARCHITECTURES ( cmake lower 2.8 method ): " ${CMAKE_OSX_ARCHITECTURES})
	ELSE(CMAKE_VERSION VERSION_LESS 2.8.1)
		MESSAGE(STATUS "CMAKE_XCODE_ATTRIBUTE_ARCHS ( cmake 2.8 or higher method ): " ${CMAKE_XCODE_ATTRIBUTE_ARCHS})
	ENDIF(CMAKE_VERSION VERSION_LESS 2.8.1)
    if(${XCODE_VERSION} VERSION_GREATER 4.3)
        MESSAGE(STATUS "OSX SDK SETTING : " ${CMAKE_XCODE_ATTRIBUTE_SDKROOT}${OSX_SYSTEM})
    else()
        MESSAGE(STATUS "OSX SDK SETTING : " ${CMAKE_OSX_SYSROOT})
    endif()
	MESSAGE(STATUS "XCODE_VERSION : " ${XCODE_VERSION})
	if(${CMAKE_GENERATOR} MATCHES "Xcode")
		MESSAGE(STATUS "BUILD_TYPE : Please set in Xcode ALL_BUILD target to aimed type")
	else()
		MESSAGE(STATUS "BUILD_TYPE : " ${CMAKE_BUILD_TYPE} " - compile with: make " )
	endif()
	MESSAGE(STATUS "UPDATE_LUXRAYS_IN_MACOS_REPO : " ${OSX_UPDATE_LUXRAYS_REPO})
	MESSAGE(STATUS "")
	MESSAGE(STATUS "#####################################################################")

ENDIF(APPLE)

###########################################################################
#
# Linux and GCC
#
###########################################################################

IF(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
	if(NOT DEFINED CMAKE_CXX_FLAGS_UPDATE_ONCE)
		SET(CMAKE_CXX_FLAGS_UPDATE_ONCE TRUE CACHE INTERNAL "")
		# Update if necessary
		SET_PROPERTY(CACHE CMAKE_CXX_FLAGS PROPERTY VALUE "${CMAKE_CXX_FLAGS} -std=c++11 -Wall -Wno-long-long -pedantic")
		SET(RELEASEFLAGS "-ftree-vectorize -funroll-loops -fvariable-expansion-in-unroller")
		SET(CMAKE_CXX_FLAGS_RELEASENATIVEOPTIMIZED "${CMAKE_CXX_FLAGS_RELEASENATIVEOPTIMIZED} -DNDEBUG -O3 -march=native ${RELEASEFLAGS}" CACHE STRING "")	#-march=native implies -mtune=native
		mark_as_advanced(CMAKE_CXX_FLAGS_RELEASENATIVEOPTIMIZED)
		SET_PROPERTY(CACHE CMAKE_CXX_FLAGS_RELEASE PROPERTY VALUE "${CMAKE_CXX_FLAGS_RELEASE} -mtune=generic ${RELEASEFLAGS}")	#Fixes github Issue #114
		IF(NOT CYGWIN)
			#-fPIC is already set by default in CMake with the following "set(CMAKE_POSITION_INDEPENDENT_CODE ON)" or
			# with shared libraries: "set_property(TARGET pyluxcore PROPERTY POSITION_INDEPENDENT_CODE ON)"
			SET_PROPERTY(CACHE CMAKE_CXX_FLAGS PROPERTY VALUE "${CMAKE_CXX_FLAGS} -fPIC")
		ENDIF(NOT CYGWIN)

		SET_PROPERTY(CACHE CMAKE_CXX_FLAGS_DEBUG PROPERTY VALUE "-O0 -g")
	endif()
ENDIF()

IF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
	if(NOT DEFINED CMAKE_EXE_LINKER_FLAGS_UPDATE_ONCE)
		SET(CMAKE_EXE_LINKER_FLAGS_UPDATE_ONCE TRUE CACHE INTERNAL "")

		SET_PROPERTY(CACHE CMAKE_EXE_LINKER_FLAGS PROPERTY VALUE -Wl,--version-script='${CMAKE_SOURCE_DIR}/cmake/exportmaps/linux_symbol_exports.map')
		SET_PROPERTY(CACHE CMAKE_SHARED_LINKER_FLAGS PROPERTY VALUE -Wl,--version-script='${CMAKE_SOURCE_DIR}/cmake/exportmaps/linux_symbol_exports.map')
		SET_PROPERTY(CACHE CMAKE_MODULE_LINKER_FLAGS PROPERTY VALUE -Wl,--version-script='${CMAKE_SOURCE_DIR}/cmake/exportmaps/linux_symbol_exports.map')
		SET(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE CACHE BOOL "")
		SET(CMAKE_INSTALL_RPATH "$ORIGIN" CACHE PATH "")
	endif()
ENDIF()

IF(CMAKE_CPACK_COMMAND)
	message(STATUS "Enable advanced on cmake-gui to see more CPACK options")
	INCLUDE(GNUInstallDirs) #Define GNU standard installation directories, like CMAKE_INSTALL_LIBDIR=lib/<multiarch-tuple> on Debian (when CMAKE_INSTALL_PREFIX=/usr/)
	SET(CPACK_COMPONENTS_ALL								Unspecified;share)			#Documentation claims this would be autopopulated, on my system it had to be manually set.
	SET(CPACK_PACKAGE_NAME									"luxcorerender")
	SET(CPACK_PACKAGE_CONTACT								"nobody@nobody.com" CACHE STRING "Package maintainer and PGP signer.")
	SET(CPACK_PACKAGE_VENDOR								"https://github.com/LuxCoreRender/LuxCore")
	SET(CPACK_PACKAGE_DISPLAY_NAME					"LuxCoreRender ${LuxCoreRender_VERSION}")						#Not a legit CPACK var?
	SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY		" - a physically correct, unbiased rendering engine ${LuxCoreRender_VERSION}")
	SET(CPACK_PACKAGE_DESCRIPTION
	"LuxCoreRender is a physically correct, unbiased rendering engine. It is built on physically based equations that model the transportation of light. This allows it to accurately capture a wide range of phenomena which most other rendering programs are simply unable to reproduce.
	You can find more information about at https://www.luxcorerender.org

	LuxCore library is the new LuxCoreRender v2.x C++ and Python API. It is released under Apache Public License v2.0 and can be freely used in open source and commercial applications.

	You can find more information about the API at https://wiki.luxcorerender.org/LuxCore_API")
	#SET(CPACK_PACKAGE_VERSION							"${LuxCoreRender_VERSION}.${LuxCoreRender_VERSION_PACKAGE}")
	SET(CPACK_PACKAGE_VERSION_MAJOR					"${LuxCoreRender_VERSION_MAJOR}")
	SET(CPACK_PACKAGE_VERSION_MINOR					"${LuxCoreRender_VERSION_MINOR}")
	SET(CPACK_PACKAGE_VERSION_PATCH					"${LuxCoreRender_VERSION_PACKAGE}")
	#An installation directory created below the installation prefix on target system:
	SET(CPACK_PACKAGE_INSTALL_DIRECTORY			"${CPACK_PACKAGE_NAME}-${LuxCoreRender_VERSION_MAJOR}.${LuxCoreRender_VERSION_MINOR}")
	SET(CPACK_RESOURCE_FILE_LICENSE					"${CMAKE_CURRENT_SOURCE_DIR}/COPYING.txt")
	SET(CPACK_WARN_ON_ABSOLUTE_INSTALL_DESTINATION TRUE)																				#Not a legit CPACK var?
	SET(CPACK_SOURCE_IGNORE_FILES build debian Debian \\\\.travis)															#Feature appears to be broken cmake 3.9.5
	SET(CPACK__USE_DISPLAY_NAME_IN_FILENAME	OFF)
	SET(CPACK_PROJECT_CONFIG_FILE "${CPACK_SOURCE_DIR}/cmake/Utils/CPackProjectConfigFile.cmake")
	mark_as_advanced(CPACK_PACKAGE_CONTACT)

	if(UNIX AND NOT APPLE AND EXISTS "/etc/debian_version") # is this a debian system ?
		#Debian, reference https://github.com/assimp/assimp/blob/master/CMakeLists.txt
		SET(CPACK_DEBIAN_PACKAGE_DEBUG					ON)						#Debug Debian packaging
		SET(CPACK_DEB_COMPONENT_INSTALL					ON) 					#Want .deb containing binaries and separate .deb containing scenes, deb component only supported above cmake 2.8.5
		SET(CPACK_DEBIAN_PACKAGE_NAME						"${CPACK_PACKAGE_NAME}")
		SET(CPACK_DEBIAN_SHARE_PACKAGE_NAME			"${CPACK_PACKAGE_NAME}-scenes")
		SET(CPACK_DEBIAN_FILE_NAME							"${CPACK_PACKAGE_NAME}${LuxCoreRender_VERSION_MAJOR}.${LuxCoreRender_VERSION_MINOR}.deb")
		SET(CPACK_DEBIAN_SHARE_FILE_NAME				"${CPACK_PACKAGE_NAME}-scenes${LuxCoreRender_VERSION_MAJOR}.${LuxCoreRender_VERSION_MINOR}.deb")
		SET(CPACK_DEBIAN_PACKAGE_PRIORITY				"optional")
		SET(CPACK_DEBIAN_PACKAGE_SECTION				"graphics")
		SET(CPACK_DEBIAN_PACKAGE_RECOMMENDS			"${CPACK_DEBIAN_SHARE_PACKAGE_NAME}")
		SET(CPACK_DEBIAN_SHARE_PACKAGE_RECOMMENDS	"")
		SET(CPACK_DEBIAN_SHARE_PACKAGE_ENHANCES	"${CPACK_DEBIAN_PACKAGE_NAME}")
		SET(CPACK_DEBIAN_PACKAGE_HOMEPAGE				"https://github.com/LuxCoreRender/LuxCore")
		SET(CPACK_DEBIAN_PACKAGE_SHLIBDEPS			ON)																									#Depends on CMAKE_INSTALL_RPATH being appropriate value
		SET(CPACK_DEBIAN_PACKAGE_DEPENDS				"libblosc1") #python3, libtbb2, libtiff5 are all detected by SHLIBDEPS, libblosc1 does not appear to be
		SET(CPACK_DEBIAN_BUILD_DEPENDS debhelper cmake pkg-config libblosc-dev python3-dev libtbb-dev libtiff5-dev)
		execute_process(COMMAND dpkg --print-architecture
			OUTPUT_VARIABLE _debian_architecture OUTPUT_STRIP_TRAILING_WHITESPACE
			RESULT_VARIABLE _debian_architecture_failed)
		SET(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${_debian_architecture}) # https://gitlab.kitware.com/cmake/community/wikis/doc/cpack/PackageGenerators
		SET(CPACK_DEBIAN_share_PACKAGE_ARCHITECTURE ${_debian_architecture})
		SET(CPACK_PACKAGE_FILE_NAME						"luxcorerender${LuxCoreRender_VERSION_MAJOR}.${LuxCoreRender_VERSION_MINOR}-Linux-${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}")
		execute_process(COMMAND lsb_release -is
			OUTPUT_VARIABLE _lsb_distribution OUTPUT_STRIP_TRAILING_WHITESPACE
			RESULT_VARIABLE _lsb_release_failed)
		SET(CPACK_DEBIAN_DISTRIBUTION_NAME ${_lsb_distribution} CACHE STRING "Name of the Linux distribution")
		STRING(TOLOWER ${CPACK_DEBIAN_DISTRIBUTION_NAME} CPACK_DEBIAN_DISTRIBUTION_NAME)
		IF( ${CPACK_DEBIAN_DISTRIBUTION_NAME} STREQUAL "ubuntu" )
			SET(CPACK_DEBIAN_DISTRIBUTION_RELEASES lucid maverick natty oneiric precise CACHE STRING "Release code-names of the distrubiton release")
			SET(CPACK_DEBIAN_DPUT_HOST "" CACHE STRING "PPA repository to upload the debian sources")
		ENDIF()
		mark_as_advanced(CPACK_DEBIAN_DISTRIBUTION_NAME)
	endif()

	#CPack has an error (infinite recursion fills up whole HDD) if the PROJECT_BINARY_DIR is subdirectory of PROJECT_SOURCE_DIR... so emit Fatal_Error if this the case:
	string(REPLACE "/" "\\/" PROJECT_SOURCE_DIR_REGEX "${PROJECT_SOURCE_DIR}/") #TODO: Use cross-platform path separator
	if("${PROJECT_BINARY_DIR}" MATCHES "${PROJECT_SOURCE_DIR_REGEX}")
		message(FATAL_ERROR "CPack will recursively fill HDD if PROJECT_BINARY_DIR is subdirectory of PROJECT_SOURCE_DIR, please move PROJECT_BINARY_DIR to parent directory. Terminating.")
	else()
		#Safe to include CPack.
		INCLUDE(CPack)
		cpack_add_component(Unspecified DISPLAY_NAME scenes DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION}")
		cpack_add_component(share DISPLAY_NAME scenes DESCRIPTION "Contains sample scenes usable by luxcorerender.")

		if(NOT DEFINED CPACK_OUPUTS_UPDATE_ONCE)		#These are defined after CPack included, and are all probably unwanted by user
			SET(CPACK_OUPUTS_UPDATE_ONCE TRUE CACHE INTERNAL "")
			SET_PROPERTY(CACHE CPACK_BINARY_STGZ PROPERTY VALUE FALSE)
			SET_PROPERTY(CACHE CPACK_BINARY_TGZ PROPERTY VALUE FALSE)
			SET_PROPERTY(CACHE CPACK_BINARY_TZ PROPERTY VALUE FALSE)
			SET_PROPERTY(CACHE CPACK_SOURCE_TBZ2 PROPERTY VALUE FALSE)
			SET_PROPERTY(CACHE CPACK_SOURCE_TGZ PROPERTY VALUE FALSE)
			SET_PROPERTY(CACHE CPACK_SOURCE_TXZ PROPERTY VALUE FALSE)
			SET_PROPERTY(CACHE CPACK_SOURCE_TZ PROPERTY VALUE FALSE)
		endif()
	endif()
	if(UNIX AND NOT APPLE AND CMAKE_SYSTEM_NAME MATCHES "Linux") # is this a Linux system?
		mark_as_advanced(CLEAR CPACK_BINARY_DEB CPACK_BINARY_RPM)
	endif()
	IF(CPACK_BINARY_DEB)
		INCLUDE(DebSourcePPA)
		mark_as_advanced(DPUT_EXECUTABLE DEBUILD_EXECUTABLE)
	ELSEIF(CPACK_BINARY_RPM)
		#RPM distributions, like Red Hat Linux
		#https://cmake.org/cmake/help/latest/module/CPackRPM.html
	ENDIF()
	IF((CPACK_BINARY_DEB OR CPACK_BINARY_RPM) AND CMAKE_BUILD_TYPE STREQUAL "ReleaseNativeOptimized")
		message("Warning: Be advised that this .deb/.rpm may not work on other systems as CMAKE_BUILD_TYPE=ReleaseNativeOptimized and is highly tuned to this system's CPU")
	ENDIF()
ENDIF()
