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
#include <QSettings>

int main(int argc, char *argv[])
{
    QApplication::setApplicationName(QStringLiteral("TitanBrowser"));
    QApplication::setApplicationVersion(QStringLiteral("1.0.0"));
    QApplication::setOrganizationName(QStringLiteral("ArchTitan"));
    QApplication::setDesktopFileName(QStringLiteral("titanbrowser"));

    // Force XCB (XWayland) to avoid Wayland GBM/Vulkan crash on NVIDIA systems.
    if (qgetenv("QT_QPA_PLATFORM").isEmpty())
        qputenv("QT_QPA_PLATFORM", "xcb");

    // Respect an explicit override so users on non-NVIDIA machines can opt back
    // into GPU acceleration. The default keeps the SwiftShader fallback that
    // avoids the NVIDIA+Wayland GBM/Vulkan SIGSEGV (see f76ae21). Note that
    // --disable-gpu means all page compositing happens on the CPU, which is why
    // the startpage avoids backdrop blur / per-shape canvas shadowBlur.
    if (qgetenv("QTWEBENGINE_CHROMIUM_FLAGS").isEmpty()) {
        qputenv("QTWEBENGINE_CHROMIUM_FLAGS",
                "--no-sandbox "
                "--disable-gpu "
                "--disable-gpu-sandbox "
                "--disable-dev-shm-usage "
                "--lang=en-US "
                "--autoplay-policy=no-user-gesture-required "
                "--enable-smooth-scrolling "
                "--renderer-process-limit=2 "
                "--disk-cache-size=134217728 "
                "--disable-features=VaapiVideoDecoder,UseChromeOSDirectVideoDecoder,"
                "IsolateOrigins,site-per-process,Translate");
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
