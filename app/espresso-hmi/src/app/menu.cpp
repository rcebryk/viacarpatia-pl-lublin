#include "menu.h"

#include <QVariantMap>

Menu::Menu(QObject *parent)
    : QObject(parent)
    , m_drinks(DrinkCatalog::defaultMenu())
{
    // Błędne menu nie zatrzymuje maszyny, ale zostawia ślad w journalctl
    const QStringList errors = DrinkCatalog::validate(m_drinks);
    for (const QString &e : errors)
        qWarning("Menu: %s", qPrintable(e));
}

QVariantList Menu::drinks() const
{
    QVariantList list;
    for (const Drink &d : m_drinks) {
        list << QVariantMap{
            { QStringLiteral("name"), d.name },
            { QStringLiteral("volume"), DrinkCatalog::volumeText(d) },
            { QStringLiteral("color"), d.color },
            { QStringLiteral("seconds"), d.brewSeconds },
            { QStringLiteral("milk"), d.milk },
        };
    }
    return list;
}

void Menu::setDrinks(const QList<Drink> &drinks)
{
    m_drinks = drinks;
    emit drinksChanged();
}

QStringList Menu::stepsFor(bool milk) const
{
    Drink d;
    d.milk = milk;
    return DrinkCatalog::stepsFor(d);
}

int Menu::stepIndexAt(int stepCount, double progress) const
{
    return DrinkCatalog::stepIndexAt(stepCount, progress);
}
