#pragma once

#include "drinkcatalog.h"

#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

// Most między logiką menu (DrinkCatalog) a QML - singleton "Menu".
class Menu : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList drinks READ drinks NOTIFY drinksChanged)

public:
    explicit Menu(QObject *parent = nullptr);

    QVariantList drinks() const;
    void setDrinks(const QList<Drink> &drinks);   // np. testy UI: dłuższe menu

    Q_INVOKABLE QStringList stepsFor(bool milk) const;
    Q_INVOKABLE int stepIndexAt(int stepCount, double progress) const;

signals:
    void drinksChanged();

private:
    QList<Drink> m_drinks;
};
