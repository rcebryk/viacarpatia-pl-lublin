#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

// Informacje "serwisowe" o maszynie, dostępne z QML jako singleton MachineInfo.
class MachineInfo : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString appVersion READ appVersion CONSTANT)
    Q_PROPERTY(QString qtVersion READ qtVersion CONSTANT)
    Q_PROPERTY(QString osName READ osName CONSTANT)
    Q_PROPERTY(QString hostName READ hostName CONSTANT)
    Q_PROPERTY(QString buildDate READ buildDate CONSTANT)

public:
    explicit MachineInfo(QObject *parent = nullptr);

    QString appVersion() const;
    QString qtVersion() const;
    QString osName() const;
    QString hostName() const;
    QString buildDate() const;

    Q_INVOKABLE QString uptime() const;
    Q_INVOKABLE void logDrink(const QString &name);
    Q_INVOKABLE void simulateCrash();

private:
    QElapsedTimer m_started;
    int m_drinksServed = 0;
};
