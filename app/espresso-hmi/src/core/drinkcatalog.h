#pragma once

#include <QList>
#include <QString>
#include <QStringList>

// Logika menu napojów niezależna od interfejsu (bez QML, bez GUI),
// dzięki czemu można ją testować jednostkowo i w CI.

struct Drink
{
    QString name;
    int volumeMl = 0;
    QString color;      // kolor kafelka, np. "#8d5b3c"
    int brewSeconds = 0;
    bool milk = false;
};

namespace DrinkCatalog {

// Menu ekspresu. Demo na żywo: dopisz tu nowy napój (np. Flat white).
QList<Drink> defaultMenu();

// Lista błędów konfiguracji menu (pusta = menu poprawne).
QStringList validate(const QList<Drink> &menu);

// Kroki parzenia wyświetlane podczas przygotowania napoju.
QStringList stepsFor(const Drink &drink);

// Który krok pokazać przy danym postępie (0.0 - 1.0) i liczbie kroków.
// Wartości spoza zakresu są przycinane; dla 0 kroków zwraca 0.
int stepIndexAt(int stepCount, double progress);

// Tekst objętości na kafelku, np. "30 ml".
QString volumeText(const Drink &drink);

} // namespace DrinkCatalog
