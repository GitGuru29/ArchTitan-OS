#include "arcitem.h"

#include <QSGGeometryNode>
#include <QSGFlatColorMaterial>
#include <QSGGeometry>

#include <algorithm>
#include <cmath>

namespace {

void buildClosedRingGeometry(QSGGeometry *geom, qreal cx, qreal cy, qreal rOut, qreal rIn)
{
    constexpr int segments = 180;
    const int vertexCount = (segments + 1) * 2;

    geom->setDrawingMode(QSGGeometry::DrawTriangleStrip);
    geom->allocate(vertexCount);
    QSGGeometry::Point2D *vertices = geom->vertexDataAsPoint2D();

    constexpr qreal degToRad = M_PI / 180.0;
    for (int i = 0; i <= segments; ++i) {
        const qreal theta = (static_cast<qreal>(i) * 360.0 / segments) * degToRad;
        const qreal cosT = std::cos(theta);
        const qreal sinT = std::sin(theta);

        vertices[2 * i].set(cx + rOut * cosT, cy + rOut * sinT);
        vertices[2 * i + 1].set(cx + rIn * cosT, cy + rIn * sinT);
    }
}

void buildArcGeometry(QSGGeometry *geom, qreal cx, qreal cy, qreal rOut, qreal rIn,
                      qreal startDeg, qreal sweepDeg, bool roundCaps)
{
    const qreal absSweep = std::abs(sweepDeg);
    if (absSweep < 0.1) {
        geom->allocate(0);
        return;
    }

    if (absSweep >= 360.0) {
        buildClosedRingGeometry(geom, cx, cy, rOut, rIn);
        return;
    }

    const int segments = std::clamp(static_cast<int>(absSweep * 1.5), 36, 240);
    constexpr qreal degToRad = M_PI / 180.0;
    const qreal startRad = startDeg * degToRad;
    const qreal sweepRad = sweepDeg * degToRad;
    const qreal endRad   = startRad + sweepRad;
    const qreal sign     = (sweepDeg >= 0) ? 1.0 : -1.0;

    const qreal rMid = (rOut + rIn) / 2.0;
    const qreal rCap = (rOut - rIn) / 2.0;

    constexpr int capSlices = 16;
    const int capTriangles = roundCaps ? (capSlices * 2) : 0;
    const int bodyTriangles = segments * 2;
    const int totalTriangles = bodyTriangles + capTriangles;
    const int totalVertices = totalTriangles * 3;

    geom->setDrawingMode(QSGGeometry::DrawTriangles);
    geom->allocate(totalVertices);
    QSGGeometry::Point2D *vertices = geom->vertexDataAsPoint2D();

    int vIdx = 0;

    // ── Main Arc Body (Triangles) ─────────────────────────────────────────
    qreal prevCos = std::cos(startRad);
    qreal prevSin = std::sin(startRad);
    qreal prevOuterX = cx + rOut * prevCos;
    qreal prevOuterY = cy + rOut * prevSin;
    qreal prevInnerX = cx + rIn * prevCos;
    qreal prevInnerY = cy + rIn * prevSin;

    for (int i = 1; i <= segments; ++i) {
        const qreal theta = startRad + (static_cast<qreal>(i) / segments) * sweepRad;
        const qreal curCos = std::cos(theta);
        const qreal curSin = std::sin(theta);
        const qreal curOuterX = cx + rOut * curCos;
        const qreal curOuterY = cy + rOut * curSin;
        const qreal curInnerX = cx + rIn * curCos;
        const qreal curInnerY = cy + rIn * curSin;

        // Triangle 1: prevOuter, curOuter, prevInner
        vertices[vIdx++].set(prevOuterX, prevOuterY);
        vertices[vIdx++].set(curOuterX, curOuterY);
        vertices[vIdx++].set(prevInnerX, prevInnerY);

        // Triangle 2: prevInner, curOuter, curInner
        vertices[vIdx++].set(prevInnerX, prevInnerY);
        vertices[vIdx++].set(curOuterX, curOuterY);
        vertices[vIdx++].set(curInnerX, curInnerY);

        prevOuterX = curOuterX;
        prevOuterY = curOuterY;
        prevInnerX = curInnerX;
        prevInnerY = curInnerY;
    }

    if (!roundCaps)
        return;

    // ── Start Cap (Semi-circle fan curving backwards) ─────────────────────
    const qreal startCapCx = cx + rMid * std::cos(startRad);
    const qreal startCapCy = cy + rMid * std::sin(startRad);
    const qreal startNormOutX = std::cos(startRad);
    const qreal startNormOutY = std::sin(startRad);
    const qreal startNormBackX = sign * std::sin(startRad);
    const qreal startNormBackY = -sign * std::cos(startRad);

    qreal prevCapX = startCapCx + rCap * startNormOutX;
    qreal prevCapY = startCapCy + rCap * startNormOutY;

    for (int k = 1; k <= capSlices; ++k) {
        const qreal phi = (static_cast<qreal>(k) / capSlices) * M_PI;
        const qreal cosP = std::cos(phi);
        const qreal sinP = std::sin(phi);
        const qreal curCapX = startCapCx + rCap * (cosP * startNormOutX + sinP * startNormBackX);
        const qreal curCapY = startCapCy + rCap * (cosP * startNormOutY + sinP * startNormBackY);

        vertices[vIdx++].set(startCapCx, startCapCy);
        vertices[vIdx++].set(prevCapX, prevCapY);
        vertices[vIdx++].set(curCapX, curCapY);

        prevCapX = curCapX;
        prevCapY = curCapY;
    }

    // ── End Cap (Semi-circle fan curving forwards) ─────────────────────────
    const qreal endCapCx = cx + rMid * std::cos(endRad);
    const qreal endCapCy = cy + rMid * std::sin(endRad);
    const qreal endNormOutX = std::cos(endRad);
    const qreal endNormOutY = std::sin(endRad);
    const qreal endNormFwdX = -sign * std::sin(endRad);
    const qreal endNormFwdY = sign * std::cos(endRad);

    prevCapX = endCapCx + rCap * endNormOutX;
    prevCapY = endCapCy + rCap * endNormOutY;

    for (int k = 1; k <= capSlices; ++k) {
        const qreal phi = (static_cast<qreal>(k) / capSlices) * M_PI;
        const qreal cosP = std::cos(phi);
        const qreal sinP = std::sin(phi);
        const qreal curCapX = endCapCx + rCap * (cosP * endNormOutX + sinP * endNormFwdX);
        const qreal curCapY = endCapCy + rCap * (cosP * endNormOutY + sinP * endNormFwdY);

        vertices[vIdx++].set(endCapCx, endCapCy);
        vertices[vIdx++].set(prevCapX, prevCapY);
        vertices[vIdx++].set(curCapX, curCapY);

        prevCapX = curCapX;
        prevCapY = curCapY;
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

void TitanArcItem::setRoundCaps(bool r)
{
    if (m_roundCaps == r) return;
    m_roundCaps = r;
    emit roundCapsChanged();
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
        sweepGeom->setDrawingMode(QSGGeometry::DrawTriangles);
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
            buildClosedRingGeometry(trackNode->geometry(), cx, cy, rOut, rIn);
        } else {
            trackNode->geometry()->allocate(0);
        }
        trackNode->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    }

    // Update active sweep
    if (sweepNode) {
        if (std::abs(m_sweepAngle) > 0.1 && m_color.alpha() > 0) {
            static_cast<QSGFlatColorMaterial *>(sweepNode->material())->setColor(m_color);
            buildArcGeometry(sweepNode->geometry(), cx, cy, rOut, rIn, m_startAngle, m_sweepAngle, m_roundCaps);
        } else {
            sweepNode->geometry()->allocate(0);
        }
        sweepNode->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    }

    return rootNode;
}
