#!/usr/bin/env bash
export LD_LIBRARY_PATH="/home/msfvenom/custom-os-build/airootfs/usr/lib:${LD_LIBRARY_PATH}"
export QML2_IMPORT_PATH="/home/msfvenom/custom-os-build/airootfs/usr/lib/qt6/qml:${QML2_IMPORT_PATH}"
export QML_IMPORT_PATH="/home/msfvenom/custom-os-build/airootfs/usr/lib/qt6/qml:${QML_IMPORT_PATH}"
exec /home/msfvenom/custom-os-build/airootfs/usr/local/bin/titan-powermenu "$@"
