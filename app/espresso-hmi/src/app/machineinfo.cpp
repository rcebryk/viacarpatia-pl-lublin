#include "machineinfo.h"

#include <QSysInfo>
#include <QtGlobal>
#include <cstdlib>

MachineInfo::MachineInfo(QObject *parent)
    : QObject(parent)
{
    m_started.start();
}

QString MachineInfo::appVersion() const
{
    return QStringLiteral(APP_VERSION);
}

QString MachineInfo::qtVersion() const
{
    return QString::fromLatin1(qVersion());
}

QString MachineInfo::osName() const
{
    // Czyta PRETTY_NAME z /etc/os-release - wersja systemu z Yocto
    return QSysInfo::prettyProductName();
}

QString MachineInfo::hostName() const
{
    return QSysInfo::machineHostName();
}

QString MachineInfo::buildDate() const
{
    return QStringLiteral(__DATE__ " " __TIME__);
}

QString MachineInfo::uptime() const
{
    const qint64 s = m_started.elapsed() / 1000;
    return QStringLiteral("%1:%2:%3")
        .arg(s / 3600, 2, 10, QLatin1Char('0'))
        .arg((s / 60) % 60, 2, 10, QLatin1Char('0'))
        .arg(s % 60, 2, 10, QLatin1Char('0'));
}

void MachineInfo::logDrink(const QString &name)
{
    ++m_drinksServed;
    qInfo("Wydano napój: %s (łącznie od startu: %d)", qPrintable(name), m_drinksServed);
}

void MachineInfo::simulateCrash()
{
    qCritical("Symulowana awaria aplikacji (abort) - systemd powinien ją podnieść");
    std::abort();
}
