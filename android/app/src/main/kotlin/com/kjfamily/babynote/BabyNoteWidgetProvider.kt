package com.kjfamily.babynote

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 베이비노트 홈 위젯 — 4개 버튼(수유/수면/기저귀/성장).
 *
 * 각 버튼 탭 → MainActivity launch + Uri로 어떤 register 페이지 열지 전달.
 * Flutter 측 `home_widget` 패키지의 widgetClicked stream으로 받아서 GoRouter로 이동.
 *
 * ── home_widget 패키지의 HomeWidgetProvider 활용 ───────────────
 * HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)로
 * PendingIntent를 만들어 RemoteViews.setOnClickPendingIntent로 연결.
 * uri 형식은 자유 — Flutter 측에서 path/host로 분기.
 */
class BabyNoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.baby_note_widget)

            views.setOnClickPendingIntent(
                R.id.widget_btn_feeding,
                openAppIntent(context, "babynote://widget/feeding")
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_sleep,
                openAppIntent(context, "babynote://widget/sleep")
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_diaper,
                openAppIntent(context, "babynote://widget/diaper")
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_growth,
                openAppIntent(context, "babynote://widget/growth")
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun openAppIntent(context: Context, deepLink: String): PendingIntent {
        return HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(deepLink)
        )
    }
}
