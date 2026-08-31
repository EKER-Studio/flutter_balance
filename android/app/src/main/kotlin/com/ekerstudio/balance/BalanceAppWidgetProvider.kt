package com.ekerstudio.balance

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceAppWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_balance).apply {
                val hasData = widgetData.getBoolean("has_data", false)

                if (!hasData) {
                    setViewVisibility(R.id.widget_content_container, View.GONE)
                    setViewVisibility(R.id.widget_empty_view, View.VISIBLE)
                    setTextViewText(R.id.widget_last_date, "")
                } else {
                    setViewVisibility(R.id.widget_content_container, View.VISIBLE)
                    setViewVisibility(R.id.widget_empty_view, View.GONE)

                    val currentWeight = widgetData.getString("current_weight", "--") ?: "--"
                    val unit = widgetData.getString("unit", "kg") ?: "kg"
                    val deltaText = widgetData.getString("delta_text", "") ?: ""
                    val deltaIsLoss = widgetData.getBoolean("delta_is_loss", false)
                    val targetWeight = widgetData.getString("target_weight", "") ?: ""
                    val goalProgressPct = widgetData.getInt("goal_progress_pct", 0)
                    val lastDate = widgetData.getString("last_entry_date", "") ?: ""

                    setTextViewText(R.id.widget_current_weight, currentWeight)
                    setTextViewText(R.id.widget_unit, unit)
                    setTextViewText(R.id.widget_last_date, lastDate)

                    if (deltaText.isNotEmpty()) {
                        setTextViewText(R.id.widget_delta_text, deltaText)
                        setViewVisibility(R.id.widget_delta_text, View.VISIBLE)
                        val colorRes = if (deltaIsLoss) R.color.widget_loss_green else R.color.widget_gain_red
                        setTextColor(R.id.widget_delta_text, ContextCompat.getColor(context, colorRes))
                    } else {
                        setViewVisibility(R.id.widget_delta_text, View.GONE)
                    }

                    if (targetWeight.isNotEmpty()) {
                        setProgressBar(R.id.widget_progress_bar, 100, goalProgressPct, false)
                        setViewVisibility(R.id.widget_progress_bar, View.VISIBLE)
                        setTextViewText(R.id.widget_target_weight, "Cel: $targetWeight ($goalProgressPct%)")
                        setViewVisibility(R.id.widget_target_weight, View.VISIBLE)
                    } else {
                        setViewVisibility(R.id.widget_progress_bar, View.GONE)
                        setViewVisibility(R.id.widget_target_weight, View.GONE)
                    }
                }

                // Open App on widget click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
