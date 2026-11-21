#include "drinkcatalog.h"

#include <QCoreApplication>
#include <QSet>

#include <algorithm>
#include <cmath>

namespace DrinkCatalog {

QList<Drink> defaultMenu()
{
    return {
        { QCoreApplication::translate("DrinkCatalog", "Espresso"),    30,  QStringLiteral("#8d5b3c"), 5, false },
        { QCoreApplication::translate("DrinkCatalog", "Doppio"),      60,  QStringLiteral("#6f4128"), 6, false },
        { QCoreApplication::translate("DrinkCatalog", "Americano"),   200, QStringLiteral("#a0714f"), 7, false },
        { QCoreApplication::translate("DrinkCatalog", "Cappuccino"),  180, QStringLiteral("#c08f62"), 8, true  },
        { QCoreApplication::translate("DrinkCatalog", "Latte"),       250, QStringLiteral("#d2ab7e"), 9, true  },
        { QCoreApplication::translate("DrinkCatalog", "Gorąca woda"), 200, QStringLiteral("#5d7b8c"), 4, false },
    };
}

QStringList validate(const QList<Drink> &menu)
{
    QStringList errors;
    QSet<QString> names;

    if (menu.isEmpty())
        errors << QStringLiteral("menu jest puste");

    for (const Drink &d : menu) {
        if (d.name.trimmed().isEmpty())
            errors << QStringLiteral("napój bez nazwy");
        else if (names.contains(d.name))
            errors << QStringLiteral("powtórzona nazwa: %1").arg(d.name);
        names.insert(d.name);

        if (d.brewSeconds <= 0)
            errors << QStringLiteral("%1: czas parzenia musi być dodatni").arg(d.name);
        if (d.volumeMl <= 0)
            errors << QStringLiteral("%1: objętość musi być dodatnia").arg(d.name);
    }
    return errors;
}

QStringList stepsFor(const Drink &drink)
{
    QStringList steps = {
        QCoreApplication::translate("DrinkCatalog", "Mielenie kawy"),
        QCoreApplication::translate("DrinkCatalog", "Ubijanie"),
        QCoreApplication::translate("DrinkCatalog", "Parzenie"),
    };
    if (drink.milk)
        steps << QCoreApplication::translate("DrinkCatalog", "Spienianie mleka");
    return steps;
}

int stepIndexAt(int stepCount, double progress)
{
    if (stepCount <= 0)
        return 0;
    const double clamped = std::clamp(progress, 0.0, 1.0);
    const int index = static_cast<int>(std::floor(clamped * stepCount));
    return std::min(index, stepCount - 1);
}

QString volumeText(const Drink &drink)
{
    return QStringLiteral("%1 ml").arg(drink.volumeMl);
}

} // namespace DrinkCatalog
