package com.ekerstudio.balance

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceAppWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_CONFIGURATION_CHANGED) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, BalanceAppWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            val widgetData = HomeWidgetPlugin.getData(context)
            onUpdate(context, appWidgetManager, appWidgetIds, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val widgetData = HomeWidgetPlugin.getData(context)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), widgetData)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val themeMode = widgetData.getString("theme_mode", "system") ?: "system"
        val isSystemDark = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        val isDark = when (themeMode) {
            "dark" -> true
            "light" -> false
            else -> isSystemDark
        }
        val layoutId = if (isDark) R.layout.widget_balance_dark else R.layout.widget_balance

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, layoutId).apply {
                val hasData = widgetData.getBoolean("has_data", false)

                if (!hasData) {
                    setViewVisibility(R.id.widget_content_container, View.GONE)
                    setViewVisibility(R.id.widget_empty_view, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_content_container, View.VISIBLE)
                    setViewVisibility(R.id.widget_empty_view, View.GONE)

                    val headerTitle = widgetData.getString("header_title", "Ostatni pomiar") ?: "Ostatni pomiar"
                    val currentWeight = widgetData.getString("current_weight", "--") ?: "--"
                    val unit = widgetData.getString("unit", "kg") ?: "kg"

                    setTextViewText(R.id.widget_header_title, headerTitle)
                    setTextViewText(R.id.widget_current_weight, currentWeight)
                    setTextViewText(R.id.widget_unit, unit)
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                val addActionPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("balance://today?action=add"),
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                setOnClickPendingIntent(R.id.widget_action_btn, addActionPendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
