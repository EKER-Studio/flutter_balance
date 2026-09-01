package com.ekerstudio.balance

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceFullAppWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_CONFIGURATION_CHANGED) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, BalanceFullAppWidgetProvider::class.java)
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
        val layoutId = if (isDark) R.layout.widget_balance_full_dark else R.layout.widget_balance_full

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
                    val deltaText = widgetData.getString("delta_text", "") ?: ""
                    val deltaIsLoss = widgetData.getBoolean("delta_is_loss", true)
                    val targetWeight = widgetData.getString("target_weight", "") ?: ""
                    val goalProgressPct = widgetData.getInt("goal_progress_pct", 0)
                    val isGoalAchieved = widgetData.getBoolean("is_goal_achieved", goalProgressPct >= 100)
                    val goalStatusText = widgetData.getString("goal_status_text", "") ?: ""
                    val lastDate = widgetData.getString("last_entry_date", "") ?: ""
                    val bmiValue = widgetData.getString("bmi_value", "") ?: ""
                    val bmiCategoryLabel = widgetData.getString("bmi_category_label", "") ?: ""

                    setTextViewText(R.id.widget_header_title, headerTitle)
                    setTextViewText(R.id.widget_current_weight, currentWeight)
                    setTextViewText(R.id.widget_unit, unit)
                    setTextViewText(R.id.widget_last_date, lastDate)

                    val deltaType = widgetData.getString("delta_type", if (deltaIsLoss) "loss" else "gain")
                    if (deltaText.isNotEmpty()) {
                        when (deltaType) {
                            "loss" -> {
                                setTextViewText(R.id.widget_delta_chip_loss, deltaText)
                                setViewVisibility(R.id.widget_delta_chip_loss, View.VISIBLE)
                                setViewVisibility(R.id.widget_delta_chip_gain, View.GONE)
                                setViewVisibility(R.id.widget_delta_chip_neutral, View.GONE)
                            }
                            "gain" -> {
                                setTextViewText(R.id.widget_delta_chip_gain, deltaText)
                                setViewVisibility(R.id.widget_delta_chip_gain, View.VISIBLE)
                                setViewVisibility(R.id.widget_delta_chip_loss, View.GONE)
                                setViewVisibility(R.id.widget_delta_chip_neutral, View.GONE)
                            }
                            "neutral" -> {
                                setTextViewText(R.id.widget_delta_chip_neutral, deltaText)
                                setViewVisibility(R.id.widget_delta_chip_neutral, View.VISIBLE)
                                setViewVisibility(R.id.widget_delta_chip_loss, View.GONE)
                                setViewVisibility(R.id.widget_delta_chip_gain, View.GONE)
                            }
                            else -> {
                                setViewVisibility(R.id.widget_delta_chip_loss, View.GONE)
                                setViewVisibility(R.id.widget_delta_chip_gain, View.GONE)
                                setViewVisibility(R.id.widget_delta_chip_neutral, View.GONE)
                            }
                        }
                    } else {
                        setViewVisibility(R.id.widget_delta_chip_loss, View.GONE)
                        setViewVisibility(R.id.widget_delta_chip_gain, View.GONE)
                        setViewVisibility(R.id.widget_delta_chip_neutral, View.GONE)
                    }

                    if (bmiValue.isNotEmpty()) {
                        val bmiCategory = widgetData.getString("bmi_category", "")
                        val bmiTextColor = when (bmiCategory) {
                            "underweight" -> if (isDark) 0xFF64B5F6.toInt() else 0xFF1565C0.toInt()
                            "normal" -> if (isDark) 0xFF81C784.toInt() else 0xFF2E7D32.toInt()
                            "overweight" -> if (isDark) 0xFFFFB74D.toInt() else 0xFFEF6C00.toInt()
                            "obeseClass1" -> if (isDark) 0xFFFF8A65.toInt() else 0xFFD84315.toInt()
                            "obeseClass2" -> if (isDark) 0xFFE57373.toInt() else 0xFFC62828.toInt()
                            "obeseClass3" -> if (isDark) 0xFFBA68C8.toInt() else 0xFF6A1B9A.toInt()
                            else -> if (isDark) 0xFFFFB74D.toInt() else 0xFFEF6C00.toInt()
                        }
                        setTextViewText(R.id.widget_bmi_category, bmiCategoryLabel)
                        setTextViewText(R.id.widget_bmi_value, "BMI $bmiValue")
                        setTextColor(R.id.widget_bmi_category, bmiTextColor)
                        setTextColor(R.id.widget_bmi_value, bmiTextColor)
                        setViewVisibility(R.id.widget_bmi_container, View.VISIBLE)
                    } else {
                        setViewVisibility(R.id.widget_bmi_container, View.GONE)
                    }

                    if (targetWeight.isNotEmpty()) {
                        setViewVisibility(R.id.widget_goal_container, View.VISIBLE)
                        setViewVisibility(R.id.widget_space_middle, View.VISIBLE)
                        setTextViewText(R.id.widget_target_weight, "Cel: $targetWeight")

                        if (isGoalAchieved) {
                            val achievedLabel = if (goalStatusText.isNotEmpty()) goalStatusText else "Cel osiągnięty!"
                            setTextViewText(R.id.widget_goal_status, achievedLabel)
                            setViewVisibility(R.id.widget_progress_bar, View.GONE)
                            setViewVisibility(R.id.widget_progress_bar_achieved, View.VISIBLE)
                            setProgressBar(R.id.widget_progress_bar_achieved, 100, 100, false)
                        } else {
                            val statusLabel = if (goalStatusText.isNotEmpty()) goalStatusText else "$goalProgressPct%"
                            setTextViewText(R.id.widget_goal_status, statusLabel)
                            setViewVisibility(R.id.widget_progress_bar, View.VISIBLE)
                            setViewVisibility(R.id.widget_progress_bar_achieved, View.GONE)
                            setProgressBar(R.id.widget_progress_bar, 100, goalProgressPct, false)
                        }
                    } else {
                        setViewVisibility(R.id.widget_goal_container, View.GONE)
                        setViewVisibility(R.id.widget_space_middle, View.GONE)
                    }
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
