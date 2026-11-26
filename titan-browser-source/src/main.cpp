#include "browser.h"
#include "adblocker.h"
#include "profilemanager.h"
#include "TitanPalette.h"
#include <QApplication>
#include <QPalette>
#include <QWebEngineProfile>
#include <QWebEngineSettings>
#include <QWebEngineCookieStore>
#include <QNetworkCookie>
#include <QDateTime>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QIODevice>
#include <QSettings>

namespace {

bool readTrimmedDmi(const char *path, QString &out)
{
    QFile f(QString::fromLatin1(path));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;
    out = QString::fromUtf8(f.readAll()).trimmed();
    return !out.isEmpty();
}

/// Returns true inside virtual machines or systems without a DRM render node,
/// falling back to SwiftShader software compositing; returns false on bare metal.
bool shouldUseSoftwareGpu()
{
    if (!QFile::exists(QStringLiteral("/dev/dri/renderD128")))
        return true;

    const char *dmiPaths[] = {
        "/sys/class/dmi/id/product_name",
        "/sys/class/dmi/id/sys_vendor",
    };
    const QString vmVendors[] = {
        QStringLiteral("qemu"),
        QStringLiteral("virtualbox"),
        QStringLiteral("vmware"),
        QStringLiteral("bochs"),
        QStringLiteral("kvm"),
    };
    for (const char *path : dmiPaths) {
        QString val;
        if (!readTrimmedDmi(path, val))
            continue;
        const QString lower = val.toLower();
        for (const QString &vm : vmVendors) {
            if (lower.contains(vm))
                return true;
        }
    }
    return false;
}

} // namespace

int main(int argc, char *argv[])
{
    QApplication::setApplicationName(QStringLiteral("TitanBrowser"));
    QApplication::setApplicationVersion(QStringLiteral("1.0.0"));
    QApplication::setOrganizationName(QStringLiteral("ArchTitan"));
    QApplication::setDesktopFileName(QStringLiteral("titanbrowser"));

    // Force XCB (XWayland) to avoid Wayland GBM/Vulkan crash on NVIDIA systems.
    if (qgetenv("QT_QPA_PLATFORM").isEmpty())
        qputenv("QT_QPA_PLATFORM", "xcb");

    // Respect an explicit override; otherwise auto-detect bare-metal DRM GPU vs
    // VM/headless software fallback so page compositing uses hardware rasterization
    // when available without breaking QEMU/VirtualBox/VMware live sessions.
    if (qgetenv("QTWEBENGINE_CHROMIUM_FLAGS").isEmpty()) {
        const QByteArray gpuFlags = shouldUseSoftwareGpu()
            ? QByteArrayLiteral("--disable-gpu --disable-gpu-sandbox ")
            : QByteArrayLiteral("--enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist ");
        const QByteArray commonFlags = QByteArrayLiteral(
            "--no-sandbox "
            "--disable-dev-shm-usage "
            "--lang=en-US "
            "--autoplay-policy=no-user-gesture-required "
            "--enable-smooth-scrolling "
            "--renderer-process-limit=2 "
            "--disk-cache-size=134217728 "
            "--disable-features=VaapiVideoDecoder,UseChromeOSDirectVideoDecoder,"
            "IsolateOrigins,site-per-process,Translate");
        qputenv("QTWEBENGINE_CHROMIUM_FLAGS", gpuFlags + commonFlags);
    }

    QApplication app(argc, argv);

    // ── Shared ArchTitan design-system palette (TitanPalette) ─────────────
    // Qt stylesheets have no variables, so the QSS below inlines the same TDL
    // values; this QPalette keeps every default-styled widget/menu/dialog and
    // the wallpaper-adaptive accent in sync with the rest of the OS.
    {
        QPalette pal = app.palette();
        pal.setColor(QPalette::Window,          TitanPalette::crust());
        pal.setColor(QPalette::WindowText,      TitanPalette::textHigh());
        pal.setColor(QPalette::Base,            TitanPalette::mantle());
        pal.setColor(QPalette::AlternateBase,   TitanPalette::base());
        pal.setColor(QPalette::Text,            TitanPalette::textHigh());
        pal.setColor(QPalette::PlaceholderText, TitanPalette::textLow());
        pal.setColor(QPalette::Button,          TitanPalette::mantle());
        pal.setColor(QPalette::ButtonText,      TitanPalette::textHigh());
        pal.setColor(QPalette::BrightText,      TitanPalette::danger());
        pal.setColor(QPalette::Highlight,       TitanPalette::accent());
        pal.setColor(QPalette::HighlightedText, TitanPalette::accentFg());
        pal.setColor(QPalette::ToolTipBase,     TitanPalette::mantle());
        pal.setColor(QPalette::ToolTipText,     TitanPalette::textHigh());
        pal.setColor(QPalette::Link,            TitanPalette::accent());
        pal.setColor(QPalette::LinkVisited,     TitanPalette::mauve());
        app.setPalette(pal);
    }

    // ── Enforce Default English (en-US) Locale & Optimize Profile ─────────
    auto *profile = QWebEngineProfile::defaultProfile();
    profile->setHttpAcceptLanguage(QStringLiteral("en-US,en;q=0.9"));
    profile->setHttpCacheType(QWebEngineProfile::DiskHttpCache);
    profile->setHttpCacheMaximumSize(128 * 1024 * 1024); // 128 MB disk cache — smaller mapped-file footprint
    profile->setPersistentCookiesPolicy(QWebEngineProfile::AllowPersistentCookies);

    // Set storage locations in user config directory
    const QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/titanbrowser");
    QDir().mkpath(dataPath);
    profile->setPersistentStoragePath(dataPath);

    // Profile-level WebEngine Settings. WebGL and the built-in PDF viewer are
    // off by default: GPU is disabled (SwiftShader) and both allocate memory
    // that most sessions never use. Settings → Performance can re-enable them.
    QSettings features(QStringLiteral("ArchTitan"), QStringLiteral("TitanBrowserFeatures"));
    const bool webglEnabled   = features.value(QStringLiteral("webgl"), false).toBool();
    const bool pdfEnabled     = features.value(QStringLiteral("pdf"),   false).toBool();

    auto *settings = profile->settings();
    settings->setAttribute(QWebEngineSettings::ScrollAnimatorEnabled, true);
    settings->setAttribute(QWebEngineSettings::Accelerated2dCanvasEnabled, true);
    settings->setAttribute(QWebEngineSettings::WebGLEnabled, webglEnabled);
    settings->setAttribute(QWebEngineSettings::DnsPrefetchEnabled, true);
    settings->setAttribute(QWebEngineSettings::FullScreenSupportEnabled, true);
    settings->setAttribute(QWebEngineSettings::FocusOnNavigationEnabled, true);
    settings->setAttribute(QWebEngineSettings::PdfViewerEnabled, pdfEnabled);
    settings->setAttribute(QWebEngineSettings::LocalContentCanAccessRemoteUrls, true);
    settings->setAttribute(QWebEngineSettings::LocalContentCanAccessFileUrls, true);
    settings->setAttribute(QWebEngineSettings::PlaybackRequiresUserGesture, false);

    // Set English preferences on YouTube & Google
    auto *cookieStore = profile->cookieStore();
    QNetworkCookie ytPref(QByteArrayLiteral("PREF"), QByteArrayLiteral("f6=40000000&hl=en&gl=US"));
    ytPref.setDomain(QStringLiteral(".youtube.com"));
    ytPref.setPath(QStringLiteral("/"));
    ytPref.setExpirationDate(QDateTime::currentDateTime().addYears(5));
    cookieStore->setCookie(ytPref, QUrl(QStringLiteral("https://www.youtube.com")));

    QNetworkCookie googlePref(QByteArrayLiteral("PREF"), QByteArrayLiteral("hl=en&gl=US"));
    googlePref.setDomain(QStringLiteral(".google.com"));
    googlePref.setPath(QStringLiteral("/"));
    googlePref.setExpirationDate(QDateTime::currentDateTime().addYears(5));
    cookieStore->setCookie(googlePref, QUrl(QStringLiteral("https://www.google.com")));

    // ── Install TitanShield Ad Blocker & Content Engine ──────────────────
    // Must be set BEFORE any QWebEngineView is created.
    auto *adBlocker = new AdBlocker(profile);
    profile->setUrlRequestInterceptor(adBlocker);
    adBlocker->installContentScript(profile);

    // Optionally load a user filter list from disk
    const QString userList = QDir::homePath() + QStringLiteral("/.config/titanbrowser/filters.txt");
    if (QFile::exists(userList))
        adBlocker->loadFilterList(userList);

    // ── Initialize Multi-Profile Manager ────────────────────────────────
    ProfileManager::instance().initialize(adBlocker);

    Browser w(adBlocker);
    w.show();

    return app.exec();
}
