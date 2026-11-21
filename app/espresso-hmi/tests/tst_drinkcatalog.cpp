#include "drinkcatalog.h"

#include <QtTest>

// Testy jednostkowe logiki menu. Uruchamiane w CI przy każdym patchsecie:
//   ctest --test-dir build --output-on-failure

class TestDrinkCatalog : public QObject
{
    Q_OBJECT

private slots:
    void defaultMenuIsValid()
    {
        const QStringList errors = DrinkCatalog::validate(DrinkCatalog::defaultMenu());
        QVERIFY2(errors.isEmpty(), qPrintable(errors.join(QStringLiteral("; "))));
    }

    void defaultMenuFitsOnScreen()
    {
        // Ekran 800x480 mieści siatkę 3 x 3 kafelki
        QVERIFY(DrinkCatalog::defaultMenu().size() <= 9);
    }

    void validateEmptyMenu()
    {
        QCOMPARE(DrinkCatalog::validate({}).size(), 1);
    }

    void validateDuplicateNames()
    {
        const QList<Drink> menu = { { "Latte", 250, "#fff", 9, true }, { "Latte", 200, "#fff", 8, true } };
        QCOMPARE(DrinkCatalog::validate(menu).size(), 1);
    }

    void validateEmptyName()
    {
        const QList<Drink> menu = { { "  ", 30, "#fff", 5, false } };
        QCOMPARE(DrinkCatalog::validate(menu).size(), 1);
    }

    void validateNonPositiveValues_data()
    {
        QTest::addColumn<int>("volume");
        QTest::addColumn<int>("seconds");
        QTest::addColumn<int>("expectedErrors");
        QTest::newRow("poprawny") << 30 << 5 << 0;
        QTest::newRow("czas 0") << 30 << 0 << 1;
        QTest::newRow("czas ujemny") << 30 << -3 << 1;
        QTest::newRow("objętość 0") << 0 << 5 << 1;
        QTest::newRow("oba złe") << 0 << 0 << 2;
    }

    void validateNonPositiveValues()
    {
        QFETCH(int, volume);
        QFETCH(int, seconds);
        QFETCH(int, expectedErrors);
        const QList<Drink> menu = { { "Espresso", volume, "#fff", seconds, false } };
        QCOMPARE(DrinkCatalog::validate(menu).size(), expectedErrors);
    }

    void stepsWithoutMilk()
    {
        Drink d;
        d.milk = false;
        QCOMPARE(DrinkCatalog::stepsFor(d).size(), 3);
    }

    void stepsWithMilkEndWithFrothing()
    {
        Drink d;
        d.milk = true;
        const QStringList steps = DrinkCatalog::stepsFor(d);
        QCOMPARE(steps.size(), 4);
        QCOMPARE(steps.last(), QStringLiteral("Spienianie mleka"));
    }

    void stepIndexAt_data()
    {
        QTest::addColumn<int>("count");
        QTest::addColumn<double>("progress");
        QTest::addColumn<int>("expected");
        QTest::newRow("start") << 4 << 0.0 << 0;
        QTest::newRow("połowa") << 4 << 0.5 << 2;
        QTest::newRow("tuż przed końcem") << 4 << 0.999 << 3;
        QTest::newRow("koniec") << 4 << 1.0 << 3;
        QTest::newRow("poniżej zera") << 4 << -0.5 << 0;
        QTest::newRow("powyżej jedynki") << 3 << 1.7 << 2;
        QTest::newRow("brak kroków") << 0 << 0.5 << 0;
    }

    void stepIndexAt()
    {
        QFETCH(int, count);
        QFETCH(double, progress);
        QFETCH(int, expected);
        QCOMPARE(DrinkCatalog::stepIndexAt(count, progress), expected);
    }

    void volumeText()
    {
        Drink d;
        d.volumeMl = 30;
        QCOMPARE(DrinkCatalog::volumeText(d), QStringLiteral("30 ml"));
    }
};

QTEST_GUILESS_MAIN(TestDrinkCatalog)
#include "tst_drinkcatalog.moc"
