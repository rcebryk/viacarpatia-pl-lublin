#include "drinkcatalog.h"
#include "menu.h"

#include <QQmlApplicationEngine>
#include <QQuickItem>
#include <QQuickWindow>
#include <QtQml/QQmlExtensionPlugin>
#include <QtTest>

Q_IMPORT_QML_PLUGIN(EspressoHmiPlugin)

// Testy interfejsu: prawdziwy Main.qml w oknie bez ekranu (QT_QPA_PLATFORM=offscreen),
// kliknięcia myszą jak na desktopie. Każdy test to regresja zgłoszonego błędu.

class TestUi : public QObject
{
    Q_OBJECT

    QQmlApplicationEngine *m_engine = nullptr;
    QQuickWindow *m_window = nullptr;

    void load(const QList<Drink> &menu)
    {
        m_engine = new QQmlApplicationEngine;
        // Singleton Menu powstaje przy pierwszym użyciu - podmieniamy menu przed załadowaniem UI
        m_engine->singletonInstance<Menu *>("EspressoHmi", "Menu")->setDrinks(menu);
        m_engine->loadFromModule("EspressoHmi", "Main");
        QVERIFY(!m_engine->rootObjects().isEmpty());
        m_window = qobject_cast<QQuickWindow *>(m_engine->rootObjects().first());
        QVERIFY(m_window);
        QVERIFY(QTest::qWaitForWindowExposed(m_window));
    }

    // Szukamy po drzewie wizualnym: delegaty widoków (kafelki) nie mają rodzica QObject
    static QQuickItem *findItem(QQuickItem *root, const QString &name)
    {
        if (root->objectName() == name)
            return root;
        for (QQuickItem *child : root->childItems()) {
            if (QQuickItem *found = findItem(child, name))
                return found;
        }
        return nullptr;
    }

    QQuickItem *item(const QString &name) const
    {
        return findItem(m_window->contentItem(), name);
    }

    void click(QQuickItem *it)
    {
        const QPointF center = it->mapToScene(QPointF(it->width() / 2, it->height() / 2));
        QTest::mouseClick(m_window, Qt::LeftButton, Qt::NoModifier, center.toPoint());
    }

    static QList<Drink> longMenu(int count)
    {
        QList<Drink> menu;
        for (int i = 1; i <= count; ++i)
            menu.append({ QStringLiteral("Napój %1").arg(i), 100, QStringLiteral("#8d5b3c"), 1, false });
        return menu;
    }

private slots:
    void cleanup()
    {
        delete m_engine;
        m_engine = nullptr;
        m_window = nullptr;
    }

    // Błąd: po dodaniu 7. napoju ostatni kafelek był poza ekranem, bez przewijania.
    void allDrinksReachable_data()
    {
        QTest::addColumn<int>("count");
        QTest::newRow("6 napojów") << 6;
        QTest::newRow("7 napojów (Flat white)") << 7;
        QTest::newRow("9 napojów") << 9;
    }

    void allDrinksReachable()
    {
        QFETCH(int, count);
        load(longMenu(count));
        QQuickItem *grid = item(QStringLiteral("drinkGrid"));
        QVERIFY(grid);

        // przewinięcie do końca (jak palcem po ekranie)
        QMetaObject::invokeMethod(grid, "positionViewAtEnd");
        QTest::qWait(50);

        QQuickItem *last = item(QStringLiteral("tile_Napój %1").arg(count));
        QVERIFY2(last, "brak kafelka ostatniego napoju");
        const QRectF tile = last->mapRectToScene(last->boundingRect());
        const QRectF view = grid->mapRectToScene(grid->boundingRect());
        QVERIFY2(view.contains(tile), "ostatni kafelek poza widocznym obszarem siatki");
        QVERIFY2(QRectF(0, 0, m_window->width(), m_window->height()).contains(tile),
                 "ostatni kafelek poza ekranem");
    }

    // Błąd: "Anuluj" na ekranie parzenia uruchamiał napój z kafelka pod przyciskiem.
    void cancelDoesNotStartAnotherDrink()
    {
        load(DrinkCatalog::defaultMenu());
        QQuickItem *brew = item(QStringLiteral("brewScreen"));
        QVERIFY(brew);

        click(item(QStringLiteral("tile_Espresso")));
        QTRY_VERIFY(brew->isVisible());
        QCOMPARE(brew->property("drink").toMap().value(QStringLiteral("name")).toString(),
                 QStringLiteral("Espresso"));

        click(item(QStringLiteral("cancelButton")));
        QTest::qWait(200);
        QVERIFY2(!brew->isVisible(), qPrintable(QStringLiteral("po Anuluj nadal parzy się: %1")
            .arg(brew->property("drink").toMap().value(QStringLiteral("name")).toString())));
    }
};

QTEST_MAIN(TestUi)
#include "tst_ui.moc"
