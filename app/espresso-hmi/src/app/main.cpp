#include <QGuiApplication>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QTranslator>
#include <QtQml/QQmlExtensionPlugin>

// Moduł QML EspressoHmi jest w bibliotece statycznej espresso-ui
Q_IMPORT_QML_PLUGIN(EspressoHmiPlugin)
#include <QSocketNotifier>

#include <csignal>
#include <sys/socket.h>
#include <unistd.h>

namespace {
// "Self-pipe": w obsłudze sygnału wolno wywołać tylko proste funkcje systemowe,
// więc tylko zapisujemy bajt do gniazda, a resztę robi pętla zdarzeń Qt.
int sigtermFd[2];

void onSigterm(int)
{
    const char c = 1;
    if (::write(sigtermFd[0], &c, 1) < 0) {
        // nic więcej nie da się zrobić w obsłudze sygnału
    }
}

// Porządne zamknięcie na SIGTERM (systemctl stop/restart). Platforma Qt eglfs
// przechwytuje SIGTERM i kończy proces kodem 1, przez co każdy restart
// wyglądałby w journalctl jak awaria.
void installSigtermHandler(QCoreApplication &app)
{
    if (::socketpair(AF_UNIX, SOCK_STREAM, 0, sigtermFd) != 0)
        return;
    auto *notifier = new QSocketNotifier(sigtermFd[1], QSocketNotifier::Read, &app);
    QObject::connect(notifier, &QSocketNotifier::activated, &app, [] {
        char c;
        if (::read(sigtermFd[1], &c, 1) < 0)
            qWarning("SIGTERM: błąd odczytu gniazda");
        qInfo("SIGTERM: zamykanie aplikacji");
        QCoreApplication::quit();
    });
    struct sigaction sa = {};
    sa.sa_handler = onSigterm;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;
    ::sigaction(SIGTERM, &sa, nullptr);
}
} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("espresso-hmi"));
    QGuiApplication::setApplicationVersion(QStringLiteral(APP_VERSION));

    // Tłumaczenia wbudowane w aplikację (:/i18n); bez pasującego - po polsku
    QTranslator translator;
    if (translator.load(QLocale(), QStringLiteral("espresso-hmi"), QStringLiteral("_"), QStringLiteral(":/i18n")))
        QCoreApplication::installTranslator(&translator);

    // Trafia do journala systemd: journalctl -u espresso-hmi
    qInfo("espresso-hmi %s start (Qt %s)", APP_VERSION, qVersion());

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.loadFromModule("EspressoHmi", "Main");

    // Po inicjalizacji platformy (eglfs), żeby nasza obsługa zastąpiła jej własną
    installSigtermHandler(app);

    return QGuiApplication::exec();
}
