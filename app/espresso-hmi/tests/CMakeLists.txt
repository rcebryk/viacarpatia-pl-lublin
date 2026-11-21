find_package(Qt6 REQUIRED COMPONENTS Test)

qt_add_executable(tst_drinkcatalog tst_drinkcatalog.cpp)
target_link_libraries(tst_drinkcatalog PRIVATE espresso-core Qt6::Test)
espresso_set_warnings(tst_drinkcatalog)

# Wynik na konsolę + raport JUnit (każda funkcja testowa osobno) dla Jenkinsa
add_test(NAME tst_drinkcatalog
         COMMAND tst_drinkcatalog -o -,txt -o ${CMAKE_BINARY_DIR}/test-results/tst_drinkcatalog.xml,junitxml)
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/test-results)

# Testy interfejsu: prawdziwy QML w oknie bez ekranu, kliknięcia myszą
find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_add_executable(tst_ui tst_ui.cpp)
target_link_libraries(tst_ui PRIVATE espresso-ui espresso-uiplugin Qt6::Test Qt6::Quick)
espresso_set_warnings(tst_ui)
add_test(NAME tst_ui
         COMMAND tst_ui -o -,txt -o ${CMAKE_BINARY_DIR}/test-results/tst_ui.xml,junitxml)
set_tests_properties(tst_ui PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;LANG=C.UTF-8")
