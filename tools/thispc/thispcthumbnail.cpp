// Miniatura das unidades de thispc:/ : ícone do disco com a barra de espaço
// usado embaixo, como em "Este Computador" no Windows 11 (azul; vermelha
// acima de 90%). Sem cache ("CacheThumbnail": false), então está sempre em dia.

#include <KIO/ThumbnailCreator>
#include <KPluginFactory>

#include <QFont>
#include <QGuiApplication>
#include <QIcon>
#include <QLocale>
#include <QPainter>
#include <QPen>
#include <QStorageInfo>
#include <QUrl>

class ThisPcThumbnail : public KIO::ThumbnailCreator
{
public:
    ThisPcThumbnail(QObject *parent, const QVariantList &args)
        : KIO::ThumbnailCreator(parent, args)
    {
    }

    KIO::ThumbnailResult create(const KIO::ThumbnailRequest &request) override
    {
        const QString path = request.url().isLocalFile() ? request.url().toLocalFile() : request.url().path();
        const QStorageInfo info(path);
        if (!info.isValid() || info.bytesTotal() <= 0) {
            return KIO::ThumbnailResult::fail();
        }
        const double used = 1.0 - double(info.bytesAvailable()) / double(info.bytesTotal());
        const bool removable = path.startsWith(QLatin1String("/run/media")) || path.startsWith(QLatin1String("/media"));

        const QSize size = request.targetSize();
        const int w = size.width(), h = size.height();
        QImage img(size, QImage::Format_ARGB32_Premultiplied);
        img.fill(Qt::transparent);
        QPainter p(&img);
        p.setRenderHint(QPainter::Antialiasing);

        // ícone do disco em cima, barra no meio, espaço livre embaixo (como o Windows)
        const int iconSize = int(h * 0.40);
        const QIcon icon = QIcon::fromTheme(removable ? QStringLiteral("drive-removable-media-usb") : QStringLiteral("drive-harddisk"));
        icon.paint(&p, QRect((w - iconSize) / 2, 0, iconSize, iconSize));

        // barra de espaço do Windows: larga e grossa, trilho claro com borda fina,
        // parte usada azul (vermelha acima de 90%), cantos retos
        const double barH = qMax(7.0, h * 0.14);
        const QRectF track(1, h * 0.45, w - 2, barH);
        p.setPen(QPen(QColor(0xBC, 0xBC, 0xBC), 1));
        p.setBrush(QColor(0xE6, 0xE6, 0xE6));
        p.drawRect(track);
        QRectF fill = track.adjusted(1, 1, -1, -1);
        fill.setWidth(qMax(1.0, fill.width() * used));
        p.fillRect(fill, used >= 0.9 ? QColor(0xDA, 0x26, 0x26) : QColor(0x26, 0xA0, 0xDA));

        // "41,1 GB livres" / "de 139 GB" (o Windows chama GiB de GB)
        const QLocale pt(QLocale::Portuguese, QLocale::Brazil);
        auto gb = [&](qint64 bytes) {
            const double v = bytes / 1073741824.0;
            return pt.toString(v, 'f', v < 100 ? 1 : 0) + QStringLiteral(" GB");
        };
        QFont font = QGuiApplication::font();
        font.setPixelSize(qMax(9, int(h * 0.145)));
        p.setFont(font);
        p.setPen(QColor(255, 255, 255, 200));
        const QRectF text(0, h * 0.45 + barH + h * 0.04, w, h * 0.5);
        p.drawText(text, Qt::AlignHCenter | Qt::AlignTop,
                   QStringLiteral("%1 livres\nde %2").arg(gb(info.bytesAvailable()), gb(info.bytesTotal())));
        p.end();
        return KIO::ThumbnailResult::pass(img);
    }
};

K_PLUGIN_CLASS_WITH_JSON(ThisPcThumbnail, "thispcthumbnail.json")

#include "thispcthumbnail.moc"
