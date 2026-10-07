// thispc:/ — "Este Computador" do Windows 11 para o Dolphin.
//
// Lista as pastas do usuário (Área de Trabalho, Documentos...) e as unidades
// montadas. Cada item é uma pasta que aponta para o lugar de verdade
// (UDS_TARGET_URL / UDS_LOCAL_PATH), então o Dolphin entra nela na mesma
// janela. As unidades têm o tipo application/x-w11-drive, que o plugin
// thispcthumbnail desenha com a barra de espaço usado.

#include <KIO/WorkerBase>

#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QLocale>
#include <QRegularExpression>
#include <QSet>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QUrl>

#include <sys/stat.h>

class KIOPluginForMetaData : public QObject
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.kde.kio.worker.thispc" FILE "thispc.json")
};

namespace
{
struct Place {
    QString id;       // nome do item em thispc:/
    QString name;     // nome mostrado
    QString path;     // onde fica de verdade
    QString icon;
    bool drive;
};

QString folderName(QStandardPaths::StandardLocation loc, const QString &fallback)
{
    const QString name = QStandardPaths::displayName(loc);
    return name.isEmpty() ? fallback : name;
}

bool isRealDrive(const QStorageInfo &s)
{
    if (!s.isValid() || !s.isReady() || s.bytesTotal() <= 0) {
        return false;
    }
    static const QList<QByteArray> fs = {"ext2", "ext3", "ext4", "btrfs", "xfs", "f2fs", "ntfs", "ntfs3",
                                         "fuseblk", "vfat", "exfat", "msdos", "jfs", "reiserfs", "zfs"};
    if (!fs.contains(s.fileSystemType())) {
        return false;
    }
    // partições de sistema que o Windows também não mostra
    const QString root = s.rootPath();
    return !(root.startsWith(QLatin1String("/boot")) || root.startsWith(QLatin1String("/var/"))
             || root.startsWith(QLatin1String("/snap")) || root.startsWith(QLatin1String("/var/lib/snapd")));
}

QList<Place> places()
{
    QList<Place> out;
    const struct {
        QStandardPaths::StandardLocation loc;
        const char *id;
        const char *fallback;
        const char *icon;
    } folders[] = {
        {QStandardPaths::DesktopLocation, "desktop", "Área de Trabalho", "user-desktop"},
        {QStandardPaths::DownloadLocation, "downloads", "Downloads", "folder-download"},
        {QStandardPaths::DocumentsLocation, "documents", "Documentos", "folder-documents"},
        {QStandardPaths::PicturesLocation, "pictures", "Imagens", "folder-pictures"},
        {QStandardPaths::MusicLocation, "music", "Músicas", "folder-music"},
        {QStandardPaths::MoviesLocation, "videos", "Vídeos", "folder-videos"},
    };
    for (const auto &f : folders) {
        const QString path = QStandardPaths::writableLocation(f.loc);
        // pastas XDG não configuradas apontam para a pasta pessoal: o Windows não mostra
        if (path.isEmpty() || path == QDir::homePath() || !QDir(path).exists()) {
            continue;
        }
        out.append({QString::fromLatin1(f.id), folderName(f.loc, QString::fromUtf8(f.fallback)), path,
                    QString::fromLatin1(f.icon), false});
    }

    QSet<QByteArray> seenDevices;
    const auto volumes = QStorageInfo::mountedVolumes();
    for (const QStorageInfo &s : volumes) {
        if (!isRealDrive(s) || seenDevices.contains(s.device())) {
            continue; // btrfs: / e /home são o mesmo disco, mostra uma vez só
        }
        seenDevices.insert(s.device());
        const QString root = s.rootPath();
        QString label = s.displayName();
        if (root == QLatin1String("/")) {
            label = QStringLiteral("Disco Local");
        } else if (label == root || label.isEmpty()) {
            label = QFileInfo(root).fileName();
        }
        const bool removable = root.startsWith(QLatin1String("/run/media")) || root.startsWith(QLatin1String("/media"));
        const QString name = root == QLatin1String("/") ? QStringLiteral("%1 (/)").arg(label) : label;
        // "sda1", "nvme1n1p5"...: sem "/" (no endereço viraria outro nível de pasta)
        QString id = QString::fromLatin1(s.device()).section(QLatin1Char('/'), -1);
        id.replace(QRegularExpression(QStringLiteral("[^A-Za-z0-9._-]")), QStringLiteral("_"));
        out.append({QStringLiteral("drive-") + id, name, root,
                    removable ? QStringLiteral("drive-removable-media-usb") : QStringLiteral("drive-harddisk"), true});
    }
    return out;
}

KIO::UDSEntry entryFor(const Place &p)
{
    KIO::UDSEntry e;
    e.reserve(10);
    e.fastInsert(KIO::UDSEntry::UDS_NAME, p.id);
    // o espaço livre vai na miniatura (thispcthumbnail): no nome quebraria a árvore de pastas
    e.fastInsert(KIO::UDSEntry::UDS_DISPLAY_NAME, p.name);
    e.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, S_IFDIR);
    e.fastInsert(KIO::UDSEntry::UDS_ACCESS, 0500);
    e.fastInsert(KIO::UDSEntry::UDS_ICON_NAME, p.icon);
    e.fastInsert(KIO::UDSEntry::UDS_MIME_TYPE,
                 p.drive ? QStringLiteral("application/x-w11-drive") : QStringLiteral("application/x-w11-folder"));
    e.fastInsert(KIO::UDSEntry::UDS_TARGET_URL, QUrl::fromLocalFile(p.path).toString());
    e.fastInsert(KIO::UDSEntry::UDS_LOCAL_PATH, p.path);
    // a "data" muda sempre: a miniatura (barra de espaço) nunca fica velha
    e.fastInsert(KIO::UDSEntry::UDS_MODIFICATION_TIME, QDateTime::currentSecsSinceEpoch());
    return e;
}

KIO::UDSEntry rootEntry()
{
    KIO::UDSEntry e;
    e.fastInsert(KIO::UDSEntry::UDS_NAME, QStringLiteral("."));
    e.fastInsert(KIO::UDSEntry::UDS_DISPLAY_NAME, QStringLiteral("Este Computador"));
    e.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, S_IFDIR);
    e.fastInsert(KIO::UDSEntry::UDS_ACCESS, 0500);
    e.fastInsert(KIO::UDSEntry::UDS_ICON_NAME, QStringLiteral("computer"));
    e.fastInsert(KIO::UDSEntry::UDS_MIME_TYPE, QStringLiteral("inode/directory"));
    return e;
}

QString itemId(const QUrl &url)
{
    // com SectionSkipEmpty o primeiro pedaço não vazio é o 0 ("/drive-x" -> "drive-x")
    return url.path().section(QLatin1Char('/'), 0, 0, QString::SectionSkipEmpty);
}
} // namespace

class ThisPcWorker : public KIO::WorkerBase
{
public:
    ThisPcWorker(const QByteArray &pool, const QByteArray &app)
        : KIO::WorkerBase("thispc", pool, app)
    {
    }

    KIO::WorkerResult listDir(const QUrl &url) override
    {
        const QString id = itemId(url);
        if (!id.isEmpty()) {
            return redirectTo(id, url);
        }
        const auto all = places();
        for (const Place &p : all) {
            listEntry(entryFor(p));
        }
        listEntry(rootEntry());
        return KIO::WorkerResult::pass();
    }

    KIO::WorkerResult stat(const QUrl &url) override
    {
        const QString id = itemId(url);
        if (id.isEmpty()) {
            statEntry(rootEntry());
            return KIO::WorkerResult::pass();
        }
        const auto all = places();
        for (const Place &p : all) {
            if (p.id == id) {
                statEntry(entryFor(p));
                return KIO::WorkerResult::pass();
            }
        }
        return KIO::WorkerResult::fail(KIO::ERR_DOES_NOT_EXIST, url.toDisplayString());
    }

private:
    KIO::WorkerResult redirectTo(const QString &id, const QUrl &url)
    {
        const auto all = places();
        for (const Place &p : all) {
            if (p.id == id) {
                redirection(QUrl::fromLocalFile(p.path));
                return KIO::WorkerResult::pass();
            }
        }
        return KIO::WorkerResult::fail(KIO::ERR_DOES_NOT_EXIST, url.toDisplayString());
    }
};

extern "C" Q_DECL_EXPORT int kdemain(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("kio_thispc"));
    if (argc != 4) {
        return -1;
    }
    ThisPcWorker worker(argv[2], argv[3]);
    worker.dispatchLoop();
    return 0;
}

#include "thispc.moc"
