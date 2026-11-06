#include "arcitem.h"

#include <QSGGeometryNode>
#include <QSGFlatColorMaterial>
#include <QSGGeometry>

#include <algorithm>
#include <cmath>

namespace {
void buildArcGeometry(QSGGeometry *geom, qreal cx, qreal cy, qreal rOut, qreal rIn, qreal startDeg, qreal sweepDeg)
{
    const qreal absSweep = std::abs(sweepDeg);
    const int segments = std::clamp(static_cast<int>(absSweep / 3.0), 12, 180);
    const int vertexCount = (segments + 1) * 2;

    geom->allocate(vertexCount);
    QSGGeometry::Point2D *vertices = geom->vertexDataAsPoint2D();

    const qreal degToRad = M_PI / 180.0;
    const qreal startRad = startDeg * degToRad;
    const qreal sweepRad = sweepDeg * degToRad;

    for (int i = 0; i <= segments; ++i) {
        const qreal t = static_cast<qreal>(i) / segments;
        const qreal theta = startRad + t * sweepRad;
        const qreal cosT = std::cos(theta);
        const qreal sinT = std::sin(theta);

        // Outer vertex
        vertices[2 * i].set(cx + rOut * cosT, cy + rOut * sinT);
        // Inner vertex
        vertices[2 * i + 1].set(cx + rIn * cosT, cy + rIn * sinT);
    }
}
} // namespace

TitanArcItem::TitanArcItem(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
    setAntialiasing(true);
}

void TitanArcItem::setColor(const QColor &c)
{
    if (m_color == c) return;
    m_color = c;
    emit colorChanged();
    update();
}

void TitanArcItem::setTrackColor(const QColor &c)
{
    if (m_trackColor == c) return;
    m_trackColor = c;
    emit trackColorChanged();
    update();
}

void TitanArcItem::setLineWidth(qreal w)
{
    if (qFuzzyCompare(m_lineWidth, w)) return;
    m_lineWidth = std::max(0.5, w);
    emit lineWidthChanged();
    update();
}

void TitanArcItem::setStartAngle(qreal a)
{
    if (qFuzzyCompare(m_startAngle, a)) return;
    m_startAngle = a;
    emit startAngleChanged();
    update();
}

void TitanArcItem::setSweepAngle(qreal a)
{
    if (qFuzzyCompare(m_sweepAngle, a)) return;
    m_sweepAngle = a;
    emit sweepAngleChanged();
    update();
}

void TitanArcItem::setShowTrack(bool s)
{
    if (m_showTrack == s) return;
    m_showTrack = s;
    emit showTrackChanged();
    update();
}

QSGNode *TitanArcItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    const qreal w = width();
    const qreal h = height();
    if (w <= 1.0 || h <= 1.0) {
        delete oldNode;
        return nullptr;
    }

    QSGNode *rootNode = oldNode;
    QSGGeometryNode *trackNode = nullptr;
    QSGGeometryNode *sweepNode = nullptr;

    if (!rootNode) {
        rootNode = new QSGNode();

        // Track Node
        trackNode = new QSGGeometryNode();
        auto *trackGeom = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 0);
        trackGeom->setDrawingMode(QSGGeometry::DrawTriangleStrip);
        trackNode->setGeometry(trackGeom);
        trackNode->setFlag(QSGNode::OwnsGeometry);

        auto *trackMat = new QSGFlatColorMaterial();
        trackNode->setMaterial(trackMat);
        trackNode->setFlag(QSGNode::OwnsMaterial);

        rootNode->appendChildNode(trackNode);

        // Sweep Node
        sweepNode = new QSGGeometryNode();
        auto *sweepGeom = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 0);
        sweepGeom->setDrawingMode(QSGGeometry::DrawTriangleStrip);
        sweepNode->setGeometry(sweepGeom);
        sweepNode->setFlag(QSGNode::OwnsGeometry);

        auto *sweepMat = new QSGFlatColorMaterial();
        sweepNode->setMaterial(sweepMat);
        sweepNode->setFlag(QSGNode::OwnsMaterial);

        rootNode->appendChildNode(sweepNode);
    } else {
        trackNode = static_cast<QSGGeometryNode *>(rootNode->firstChild());
        sweepNode = static_cast<QSGGeometryNode *>(trackNode ? trackNode->nextSibling() : nullptr);
    }

    const qreal cx = w / 2.0;
    const qreal cy = h / 2.0;
    const qreal rOut = std::min(w, h) / 2.0;
    const qreal rIn = std::max(0.0, rOut - m_lineWidth);

    // Update track
    if (trackNode) {
        if (m_showTrack && m_trackColor.alpha() > 0) {
            static_cast<QSGFlatColorMaterial *>(trackNode->material())->setColor(m_trackColor);
            buildArcGeometry(trackNode->geometry(), cx, cy, rOut, rIn, 0.0, 360.0);
        } else {
            trackNode->geometry()->allocate(0);
        }
        trackNode->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    }

    // Update active sweep
    if (sweepNode) {
        if (std::abs(m_sweepAngle) > 0.1 && m_color.alpha() > 0) {
            static_cast<QSGFlatColorMaterial *>(sweepNode->material())->setColor(m_color);
            buildArcGeometry(sweepNode->geometry(), cx, cy, rOut, rIn, m_startAngle, m_sweepAngle);
        } else {
            sweepNode->geometry()->allocate(0);
        }
        sweepNode->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    }

    return rootNode;
}
