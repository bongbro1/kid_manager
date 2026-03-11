package com.example.kid_manager

import android.content.Context
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration

class FirestoreRuleSyncManager(
    private val context: Context
) {
    companion object {
        private const val TAG = "FirestoreRuleSync"
        private const val RULE_PREFS = "watcher_rules"
        private const val KEY_BLOCKED_PACKAGES = "blocked_packages"
    }

    private var appsListener: ListenerRegistration? = null
    private val ruleListeners = mutableMapOf<String, ListenerRegistration>()
    private var currentChildId: String? = null

    fun start(childId: String) {
        if (currentChildId == childId && appsListener != null) {
            // Log.d(TAG, "Already syncing rules for childId=$childId")
            return
        }

        stop()
        currentChildId = childId

        // Log.d(TAG, "Start syncing Firestore rules for childId=$childId")

        appsListener = FirebaseFirestore.getInstance()
            .collection("blocked_items")
            .document(childId)
            .collection("apps")
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    // Log.e(TAG, "Apps listener error", error)
                    return@addSnapshotListener
                }

                if (snapshot == null) {
                    // Log.d(TAG, "Apps snapshot is null")
                    return@addSnapshotListener
                }

                val currentPackages = snapshot.documents.map { it.id }.toSet()
                // Log.d(TAG, "Apps changed: $currentPackages")

                for (pkg in currentPackages) {
                    if (!ruleListeners.containsKey(pkg)) {
                        attachRuleListener(childId, pkg)
                    }
                }

                val removed = ruleListeners.keys.filter { !currentPackages.contains(it) }
                for (pkg in removed) {
                    // Log.d(TAG, "Removing listener for deleted app: $pkg")
                    ruleListeners[pkg]?.remove()
                    ruleListeners.remove(pkg)
                    removeRuleFromPrefs(pkg)
                }

                saveBlockedPackageSet(currentPackages)
            }
    }

    fun stop() {
        appsListener?.remove()
        appsListener = null

        for (listener in ruleListeners.values) {
            listener.remove()
        }
        ruleListeners.clear()

        currentChildId = null
        // Log.d(TAG, "Stopped Firestore rule sync")
    }

    private fun attachRuleListener(childId: String, packageName: String) {
        // Log.d(TAG, "Attach rule listener for package=$packageName")

        val listener = FirebaseFirestore.getInstance()
            .collection("blocked_items")
            .document(childId)
            .collection("apps")
            .document(packageName)
            .collection("usage_rule")
            .document("config")
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    // Log.e(TAG, "Rule listener error for $packageName", error)
                    return@addSnapshotListener
                }

                if (snapshot == null || !snapshot.exists()) {
                    // Log.d(TAG, "Rule missing for package=$packageName")
                    removeRuleFromPrefs(packageName)
                    return@addSnapshotListener
                }

                val data = snapshot.data
                if (data == null) {
                    // Log.d(TAG, "Rule data null for package=$packageName")
                    removeRuleFromPrefs(packageName)
                    return@addSnapshotListener
                }

                // Log.d(TAG, "Rule changed for $packageName -> $data")
                saveRuleToPrefs(packageName, data)
            }

        ruleListeners[packageName] = listener
    }

    private fun saveBlockedPackageSet(packages: Set<String>) {
        val prefs = context.getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putStringSet(KEY_BLOCKED_PACKAGES, packages)
            .apply()

        // Log.d(TAG, "Saved blocked package set: $packages")
    }

    private fun saveRuleToPrefs(packageName: String, data: Map<String, Any>) {
        val prefs = context.getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)
        val editor = prefs.edit()

        val enabled = data["enabled"] as? Boolean ?: true
        editor.putBoolean("${packageName}_enabled", enabled)

        val weekdays = (data["weekdays"] as? List<*>) ?: emptyList<Any>()
        editor.putString(
            "${packageName}_weekdays",
            weekdays.joinToString(",") { it.toString() }
        )

        val windows = (data["windows"] as? List<*>) ?: emptyList<Any>()
        val windowPairs = windows.mapNotNull { item ->
            val map = item as? Map<*, *> ?: return@mapNotNull null
            val startMin = (map["startMin"] as? Number)?.toInt() ?: return@mapNotNull null
            val endMin = (map["endMin"] as? Number)?.toInt() ?: return@mapNotNull null
            "$startMin-$endMin"
        }
        editor.putString("${packageName}_windows", windowPairs.joinToString(","))

        val overrides = (data["overrides"] as? Map<*, *>) ?: emptyMap<String, String>()
        val overridePairs = overrides.mapNotNull { (k, v) ->
            val key = k?.toString() ?: return@mapNotNull null
            val value = v?.toString() ?: return@mapNotNull null
            "$key=$value"
        }
        editor.putString("${packageName}_overrides", overridePairs.joinToString(","))

        editor.apply()

        // Log.d(TAG, "Saved rule for package=$packageName")
    }

    private fun removeRuleFromPrefs(packageName: String) {
        val prefs = context.getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)

        prefs.edit()
            .remove("${packageName}_enabled")
            .remove("${packageName}_weekdays")
            .remove("${packageName}_windows")
            .remove("${packageName}_overrides")
            .apply()

        // Log.d(TAG, "Removed rule from prefs for package=$packageName")
    }
}