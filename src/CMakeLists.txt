# Generate mceiface.h
find_program(QDBUSXML2CPP NAMES qdbusxml2cpp-qt5 qdbusxml2cpp)
if(NOT QDBUSXML2CPP)
	message(FATAL_ERROR "qdbusxml2cpp not found")
endif()
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/mceiface.h ${CMAKE_CURRENT_BINARY_DIR}/mceiface.cpp
	COMMAND ${QDBUSXML2CPP} -p mceiface.h:mceiface.cpp ${CMAKE_CURRENT_SOURCE_DIR}/mce.xml)

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/VolumeControl2.h ${CMAKE_CURRENT_BINARY_DIR}/VolumeControl2.cpp
	COMMAND ${QDBUSXML2CPP} -p VolumeControl2.h:VolumeControl2.cpp ${CMAKE_CURRENT_SOURCE_DIR}/VolumeControl2.xml)

set(SRC
	main.cpp
	sysinfo.cpp
	taptowake.cpp
	tilttowake.cpp
	volumecontrol.cpp)
set(HEADERS
	sysinfo.h
	taptowake.h
	tilttowake.h
	volumecontrol.h)

find_package(Qt5QuickCompiler)
if(Qt5QuickCompiler_FOUND)
    qtquick_compiler_add_resources(RESOURCES resources.qrc)
else()
    qt5_add_resources(RESOURCES resources.qrc)
endif()

add_library(bolide-settings ${SRC} ${HEADERS} ${RESOURCES}
    ${CMAKE_CURRENT_BINARY_DIR}/mceiface.h 
    ${CMAKE_CURRENT_BINARY_DIR}/mceiface.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/VolumeControl2.h 
    ${CMAKE_CURRENT_BINARY_DIR}/VolumeControl2.cpp
)
set_target_properties(bolide-settings PROPERTIES PREFIX "")

target_link_libraries(bolide-settings PRIVATE
	Qt5::Qml
	Qt5::Quick
	Qt5::DBus
	Qt5::Multimedia
	AsteroidApp)

install(TARGETS bolide-settings
	DESTINATION ${CMAKE_INSTALL_LIBDIR})
