// Miniatura das unidades de thispc:/ : ícone do disco com a barra de espaço
// usado embaixo, como em "Este Computador" no Windows 11 (azul; vermelha
// acima de 90%). Sem cache ("CacheThumbnail": false), então está sempre em dia.

#include <KIO/ThumbnailCreator>
#include <KPluginFactory>

#include <QIcon>
#include <QPainter>
#include <QPainterPath>
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

        // ícone do disco em cima
        const int iconSize = int(h * 0.62);
        const QIcon icon = QIcon::fromTheme(removable ? QStringLiteral("drive-removable-media-usb") : QStringLiteral("drive-harddisk"));
        icon.paint(&p, QRect((w - iconSize) / 2, int(h * 0.06), iconSize, iconSize));

        // barra de espaço: trilho cinza, parte usada azul (vermelha quando quase cheia)
        const double barW = w * 0.86, barH = qMax(4.0, h * 0.075);
        const QRectF track((w - barW) / 2, h * 0.80, barW, barH);
        QPainterPath trackPath;
        trackPath.addRoundedRect(track, barH / 2, barH / 2);
        p.fillPath(trackPath, QColor(255, 255, 255, 60));
        QRectF fill = track;
        fill.setWidth(qMax(barH, track.width() * used));
        QPainterPath fillPath;
        fillPath.addRoundedRect(fill, barH / 2, barH / 2);
        p.fillPath(fillPath, used >= 0.9 ? QColor(0xE8, 0x11, 0x23) : QColor(0x4C, 0xC2, 0xFF));
        p.end();
        return KIO::ThumbnailResult::pass(img);
    }
};

K_PLUGIN_CLASS_WITH_JSON(ThisPcThumbnail, "thispcthumbnail.json")

#include "thispcthumbnail.moc"
