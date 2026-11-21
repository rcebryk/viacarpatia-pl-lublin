cmake_minimum_required(VERSION 3.21)

# Wersja aplikacji - widoczna na ekranie serwisowym.
# Na prawdziwej maszynie to pierwsze pytanie serwisanta: "co tu jest zainstalowane?"
project(espresso-hmi VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(ESPRESSO_BUILD_TESTS "Buduj testy jednostkowe" ON)
option(ESPRESSO_WERROR "Ostrzeżenia kompilatora jako błędy (CI)" OFF)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Quick)
# LinguistTools (lupdate/lrelease) są opcjonalne: build w Yocto i w SDK działa bez nich
find_package(Qt6 6.5 OPTIONAL_COMPONENTS LinguistTools)
qt_standard_project_setup(REQUIRES 6.5)
if(QT_KNOWN_POLICY_QTP0004)
    qt_policy(SET QTP0004 NEW)   # pliki QML w podkatalogu qml/
endif()

function(espresso_set_warnings target)
    target_compile_options(${target} PRIVATE -Wall -Wextra -Wpedantic)
    if(ESPRESSO_WERROR)
        target_compile_options(${target} PRIVATE -Werror)
    endif()
endfunction()

# --- logika bez GUI: testowalna jednostkowo --------------------------------
add_library(espresso-core STATIC
    src/core/drinkcatalog.h
    src/core/drinkcatalog.cpp
)
target_include_directories(espresso-core PUBLIC src/core)
target_link_libraries(espresso-core PUBLIC Qt6::Core)
espresso_set_warnings(espresso-core)

# --- interfejs: moduł QML w bibliotece (aplikacja i testy UI linkują to samo) --
qt_add_library(espresso-ui STATIC)
qt_add_qml_module(espresso-ui
    URI EspressoHmi
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/EspressoHmi   # katalog zgodny z URI (qmllint, narzędzia)
    QML_FILES
        qml/Main.qml
        qml/DrinkTile.qml
        qml/BrewScreen.qml
        qml/ServicePanel.qml
    SOURCES
        src/app/machineinfo.h
        src/app/machineinfo.cpp
        src/app/menu.h
        src/app/menu.cpp
)

target_compile_definitions(espresso-ui PUBLIC APP_VERSION="${PROJECT_VERSION}")
target_include_directories(espresso-ui PUBLIC src/app)
target_link_libraries(espresso-ui PUBLIC espresso-core Qt6::Quick)
espresso_set_warnings(espresso-ui)

# --- aplikacja ---------------------------------------------------------------
qt_add_executable(espresso-hmi src/app/main.cpp)
target_link_libraries(espresso-hmi PRIVATE espresso-ui espresso-uiplugin Qt6::Quick)
espresso_set_warnings(espresso-hmi)

# --- tłumaczenia (pliki .ts aktualizowane w CI: cel update_translations) -----
if(TARGET Qt6::lupdate)
    qt_add_translations(TARGETS espresso-hmi
        TS_FILES i18n/espresso-hmi_en.ts
        SOURCE_TARGETS espresso-ui espresso-core
        LUPDATE_OPTIONS -locations none -no-obsolete
    )
endif()

# --- testy ---------------------------------------------------------------------
if(ESPRESSO_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

include(GNUInstallDirs)
install(TARGETS espresso-hmi RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
