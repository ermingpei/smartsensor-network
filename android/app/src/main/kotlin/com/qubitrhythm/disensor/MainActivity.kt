package com.qubitrhythm.disensor

import android.content.Context
import android.os.Build
import android.telephony.CellInfo
import android.telephony.CellInfoGsm
import android.telephony.CellInfoLte
import android.telephony.CellInfoNr
import android.telephony.CellInfoWcdma
import android.telephony.TelephonyManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.disensor/cellular"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getSignalStrengths") {
                val data = getSignalStrengths()
                if (data != null) {
                    result.success(data)
                } else {
                    result.error("UNAVAILABLE", "Cellular data not available", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getSignalStrengths(): List<Map<String, Any>>? {
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        
        // Use a dummy list if permission is missing (Flutter checks permission first)
        // In real execution, Flutter side ensures permission is granted.
        
        var cellInfos: List<CellInfo>? = null
        try {
            cellInfos = telephonyManager.allCellInfo
        } catch (e: SecurityException) {
            return null
        }

        if (cellInfos == null) return emptyList()

        val dataList = mutableListOf<Map<String, Any>>()

        for (info in cellInfos) {
            val cellData = mutableMapOf<String, Any>()
            
            if (info is CellInfoLte) {
                cellData["type"] = "LTE"
                cellData["dbm"] = info.cellSignalStrength.dbm
                cellData["cid"] = info.cellIdentity.ci
                cellData["mcc"] = info.cellIdentity.mccString ?: ""
                cellData["mnc"] = info.cellIdentity.mncString ?: ""
            } else if (info is CellInfoWcdma) {
                cellData["type"] = "WCDMA"
                cellData["dbm"] = info.cellSignalStrength.dbm
                cellData["cid"] = info.cellIdentity.cid
                 cellData["mcc"] = info.cellIdentity.mccString ?: ""
                cellData["mnc"] = info.cellIdentity.mncString ?: ""
            } else if (info is CellInfoGsm) {
                cellData["type"] = "GSM"
                cellData["dbm"] = info.cellSignalStrength.dbm
                cellData["cid"] = info.cellIdentity.cid
                 cellData["mcc"] = info.cellIdentity.mccString ?: ""
                cellData["mnc"] = info.cellIdentity.mncString ?: ""
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && info is CellInfoNr) {
                cellData["type"] = "5G" // NR
                cellData["dbm"] = (info as CellInfoNr).cellSignalStrength.dbm
                // CellIdentityNr is complex, keeping simple for now
                cellData["cid"] = 0 
            }

            if (cellData.isNotEmpty()) {
                cellData["registered"] = info.isRegistered
                dataList.add(cellData)
            }
        }
        return dataList
    }
}
