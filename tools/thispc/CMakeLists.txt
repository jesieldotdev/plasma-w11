cmake_minimum_required(VERSION 3.20)
project(thispc LANGUAGES CXX)

# "Este Computador" do Windows 11 no Dolphin:
#  - kio_thispc: lista pastas do usuário e unidades em thispc:/ (navega na mesma janela);
#  - thispcthumbnail: miniatura das unidades com a barra de espaço usado.
find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui)
find_package(KF6 REQUIRED COMPONENTS KIO CoreAddons)

kcoreaddons_add_plugin(kio_thispc SOURCES thispc.cpp INSTALL_NAMESPACE "kf6/kio")
target_link_libraries(kio_thispc KF6::KIOCore Qt6::Core)

kcoreaddons_add_plugin(thispcthumbnail SOURCES thispcthumbnail.cpp INSTALL_NAMESPACE "kf6/thumbcreator")
target_link_libraries(thispcthumbnail KF6::KIOGui Qt6::Gui)
