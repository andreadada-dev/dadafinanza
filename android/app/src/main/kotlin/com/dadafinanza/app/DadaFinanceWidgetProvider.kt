package com.dadafinanza.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.net.Uri
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Currency
import java.util.Locale
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

internal object DadaWidgetConfig {
    private const val PREFS = "dada_widget_config"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun account(context: Context, id: Int): String? =
        prefs(context).getString("widget_${id}_account", null)?.takeIf { it.isNotBlank() }

    fun category(context: Context, id: Int): String? =
        prefs(context).getString("widget_${id}_category", null)?.takeIf { it.isNotBlank() }

    fun destination(context: Context, id: Int): String? =
        prefs(context).getString("widget_${id}_destination", null)?.takeIf { it.isNotBlank() }

    fun type(context: Context, id: Int): String =
        prefs(context).getString("widget_${id}_type", "expense") ?: "expense"

    fun amount(context: Context, id: Int, index: Int): String =
        prefs(context).getString(
            "widget_${id}_amount_$index",
            listOf("1", "2", "5", "10")[index],
        ) ?: listOf("1", "2", "5", "10")[index]

    fun showBalance(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("widget_${id}_show_balance", false)

    fun showAmounts(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("widget_${id}_show_amounts", true)

    fun clear(context: Context, id: Int) {
        val editor = prefs(context).edit()
        prefs(context).all.keys
            .filter { it.startsWith("widget_${id}_") }
            .forEach(editor::remove)
        editor.apply()
    }
}

private object DadaWidgetIntents {
    fun openApp(context: Context) =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)

    fun quickAddIntent(
        context: Context,
        type: String = "expense",
        category: String? = null,
        account: String? = null,
        toAccount: String? = null,
        amount: String? = null,
        voice: Boolean = false,
        presetId: Int? = null,
        requestCode: Int,
    ) = HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.Builder()
            .scheme("dadafinanza")
            .authority("quick-add")
            .appendQueryParameter("type", type)
            .apply {
                category?.takeIf { it.isNotBlank() }
                    ?.let { appendQueryParameter("category", it) }
                account?.takeIf { it.isNotBlank() }
                    ?.let { appendQueryParameter("account", it) }
                toAccount?.takeIf { it.isNotBlank() }
                    ?.let { appendQueryParameter("toAccount", it) }
                amount?.takeIf { it.isNotBlank() }
                    ?.let { appendQueryParameter("amount", it) }
                if (voice) appendQueryParameter("voice", "1")
                presetId?.let { appendQueryParameter("presetId", it.toString()) }
                appendQueryParameter("request", requestCode.toString())
            }
            .build(),
    )

    private fun localeTag(code: String): String =
        when (code) {
            "it" -> "it-IT"
            "en" -> "en-US"
            "es" -> "es-ES"
            "fr" -> "fr-FR"
            "de" -> "de-DE"
            "pt" -> "pt-BR"
            "ru" -> "ru-RU"
            "zh" -> "zh-CN"
            "ja" -> "ja-JP"
            "ko" -> "ko-KR"
            "ar" -> "ar"
            "hi" -> "hi-IN"
            else -> code
        }

    fun localizedContext(
        context: Context,
        widgetData: SharedPreferences,
    ): Context {
        val code = widgetData.getString("language_code", "it") ?: "it"
        if (code == "system") return context
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(localeTag(code)))
        return context.createConfigurationContext(configuration)
    }

    fun locale(
        context: Context,
        widgetData: SharedPreferences,
    ): Locale = localizedContext(context, widgetData).resources.configuration.locales[0]

    fun balanceLabel(
        context: Context,
        widgetData: SharedPreferences,
        reveal: Boolean = true,
    ): String {
        if (!reveal || widgetData.getBoolean("hide_balance", false)) return "••••"
        val balance = widgetData.getString("balance", "0.00") ?: "0.00"
        val currency = widgetData.getString("currency", "EUR") ?: "EUR"
        return moneyLabel(balance, currency, locale(context, widgetData))
    }

    fun moneyLabel(
        amount: String,
        currency: String,
        locale: Locale,
    ): String {
        val numeric = amount.replace(',', '.').toDoubleOrNull() ?: 0.0
        val formatter = NumberFormat.getCurrencyInstance(locale)
        runCatching {
            formatter.currency = Currency.getInstance(currency.uppercase())
        }
        return formatter.format(numeric)
    }
}
class DadaFinanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val localized = DadaWidgetIntents.localizedContext(context, widgetData)
            val quick = List(4) { index ->
                widgetData.getString("quick_category_$index", "Spesa") ?: "Spesa"
            }
            val quickLabels = List(4) { index ->
                widgetData.getString("quick_category_label_$index", null)
                    ?.takeIf { it.isNotBlank() }
                    ?: if (quick[index] == "Spesa") {
                        localized.getString(R.string.widget_expense)
                    } else {
                        quick[index]
                    }
            }
            val reveal = DadaWidgetConfig.showBalance(context, widgetId)
            val views = RemoteViews(context.packageName, R.layout.dada_finance_widget).apply {
                setTextViewText(
                    R.id.widget_balance,
                    DadaWidgetIntents.balanceLabel(context, widgetData, reveal),
                )
                setTextViewText(R.id.widget_quick_0, quickLabels[0])
                setTextViewText(R.id.widget_quick_1, quickLabels[1])
                setTextViewText(R.id.widget_quick_2, quickLabels[2])
                setTextViewText(R.id.widget_quick_3, quickLabels[3])
                setContentDescription(
                    R.id.widget_add,
                    localized.getString(R.string.widget_add_expense),
                )
                setOnClickPendingIntent(R.id.widget_root, DadaWidgetIntents.openApp(context))
                setOnClickPendingIntent(
                    R.id.widget_add,
                    DadaWidgetIntents.quickAddIntent(
                        context,
                        requestCode = widgetId * 10,
                    ),
                )
                listOf(
                    R.id.widget_quick_0,
                    R.id.widget_quick_1,
                    R.id.widget_quick_2,
                    R.id.widget_quick_3,
                ).forEachIndexed { index, viewId ->
                    setOnClickPendingIntent(
                        viewId,
                        DadaWidgetIntents.quickAddIntent(
                            context,
                            category = quick[index],
                            requestCode = widgetId * 10 + index + 1,
                        ),
                    )
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        appWidgetIds.forEach { DadaWidgetConfig.clear(context, it) }
    }
}

class DadaBalanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val localized = DadaWidgetIntents.localizedContext(context, widgetData)
            val views = RemoteViews(context.packageName, R.layout.dada_balance_widget).apply {
                setTextViewText(
                    R.id.balance_widget_title,
                    localized.getString(R.string.widget_balance_total),
                )
                setTextViewText(
                    R.id.balance_widget_value,
                    DadaWidgetIntents.balanceLabel(
                        context,
                        widgetData,
                        DadaWidgetConfig.showBalance(context, widgetId),
                    ),
                )
                setContentDescription(
                    R.id.balance_widget_add,
                    localized.getString(R.string.widget_add_expense),
                )
                setOnClickPendingIntent(
                    R.id.balance_widget_root,
                    DadaWidgetIntents.openApp(context),
                )
                setOnClickPendingIntent(
                    R.id.balance_widget_add,
                    DadaWidgetIntents.quickAddIntent(
                        context,
                        requestCode = widgetId * 20 + 1,
                    ),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        appWidgetIds.forEach { DadaWidgetConfig.clear(context, it) }
    }
}

class DadaQuickAddWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val localized = DadaWidgetIntents.localizedContext(context, widgetData)
            val account = DadaWidgetConfig.account(context, widgetId)
            val category = DadaWidgetConfig.category(context, widgetId)
            val destination = DadaWidgetConfig.destination(context, widgetId)
            val contextLabel = listOfNotNull(account, category).joinToString(" · ")
                .ifBlank { "DadaFinanza" }
            val views = RemoteViews(context.packageName, R.layout.dada_quick_add_widget).apply {
                setTextViewText(
                    R.id.quick_widget_title,
                    localized.getString(R.string.widget_quick_title),
                )
                setTextViewText(R.id.quick_widget_context, contextLabel)
                setTextViewText(
                    R.id.quick_widget_expense,
                    localized.getString(R.string.widget_expense),
                )
                setTextViewText(
                    R.id.quick_widget_income,
                    localized.getString(R.string.widget_income),
                )
                setTextViewText(
                    R.id.quick_widget_transfer,
                    localized.getString(R.string.widget_transfer),
                )
                setTextViewText(
                    R.id.quick_widget_voice,
                    "🎙 " + localized.getString(R.string.widget_voice),
                )
                setContentDescription(
                    R.id.quick_widget_expense,
                    localized.getString(R.string.widget_new_expense),
                )
                setContentDescription(
                    R.id.quick_widget_income,
                    localized.getString(R.string.widget_new_income),
                )
                setContentDescription(
                    R.id.quick_widget_transfer,
                    localized.getString(R.string.widget_new_transfer),
                )
                setContentDescription(
                    R.id.quick_widget_voice,
                    localized.getString(R.string.widget_voice_description),
                )
                setOnClickPendingIntent(R.id.quick_widget_root, DadaWidgetIntents.openApp(context))
                setOnClickPendingIntent(
                    R.id.quick_widget_expense,
                    DadaWidgetIntents.quickAddIntent(
                        context,
                        type = "expense",
                        account = account,
                        category = category,
                        requestCode = widgetId * 30 + 1,
                    ),
                )
                setOnClickPendingIntent(
                    R.id.quick_widget_income,
                    DadaWidgetIntents.quickAddIntent(
                        context,
                        type = "income",
                        account = account,
                        requestCode = widgetId * 30 + 2,
                    ),
                )
                setOnClickPendingIntent(
                    R.id.quick_widget_transfer,
                    DadaWidgetIntents.quickAddIntent(
                        context,
                        type = "transfer",
                        account = account,
                        toAccount = destination,
                        requestCode = widgetId * 30 + 3,
                    ),
                )
                setOnClickPendingIntent(
                    R.id.quick_widget_voice,
                    DadaWidgetIntents.quickAddIntent(
                        context,
                        type = DadaWidgetConfig.type(context, widgetId),
                        account = account,
                        category = category,
                        toAccount = destination,
                        voice = true,
                        requestCode = widgetId * 30 + 4,
                    ),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        appWidgetIds.forEach { DadaWidgetConfig.clear(context, it) }
    }
}

class DadaQuickAmountsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val localized = DadaWidgetIntents.localizedContext(context, widgetData)
            val widgetLocale = DadaWidgetIntents.locale(context, widgetData)
            val type = DadaWidgetConfig.type(context, widgetId)
            val account = DadaWidgetConfig.account(context, widgetId)
            val category = DadaWidgetConfig.category(context, widgetId)
            val destination = DadaWidgetConfig.destination(context, widgetId)
            val showAmounts = DadaWidgetConfig.showAmounts(context, widgetId)
            val amounts = List(4) { DadaWidgetConfig.amount(context, widgetId, it) }
            val contextLabel = listOfNotNull(account, category).joinToString(" · ")
                .ifBlank { localized.getString(R.string.widget_configure_account_category) }

            val views = RemoteViews(context.packageName, R.layout.dada_quick_amounts_widget).apply {
                setTextViewText(
                    R.id.amount_widget_title,
                    localized.getString(R.string.widget_fast_title),
                )
                setTextViewText(R.id.amount_widget_context, contextLabel)
                setTextViewText(
                    R.id.amount_widget_expense,
                    localized.getString(R.string.widget_expense),
                )
                setTextViewText(
                    R.id.amount_widget_income,
                    localized.getString(R.string.widget_income),
                )
                setContentDescription(
                    R.id.amount_widget_voice,
                    localized.getString(R.string.widget_voice_description),
                )
                setOnClickPendingIntent(R.id.amount_widget_root, DadaWidgetIntents.openApp(context))
                val amountViews = listOf(
                    R.id.amount_widget_0,
                    R.id.amount_widget_1,
                    R.id.amount_widget_2,
                    R.id.amount_widget_3,
                )
                amountViews.forEachIndexed { index, viewId ->
                    val currency = widgetData.getString("currency", "EUR") ?: "EUR"
                    setTextViewText(
                        viewId,
                        if (showAmounts) {
                            DadaWidgetIntents.moneyLabel(
                                amounts[index],
                                currency,
                                widgetLocale,
                            )
                        } else {
                            "••"
                        },
                    )
                    setOnClickPendingIntent(
                        viewId,
                        DadaWidgetIntents.quickAddIntent(
                            context,
                            type = type,
                            account = account,
                            category = if (type == "expense") category else null,
                            toAccount = if (type == "transfer") destination else null,
                            amount = amounts[index],
                            requestCode = widgetId * 40 + index + 1,
                        ),
                    )
                }
                setOnClickPendingIntent(
                    R.id.amount_widget_expense,
                    DadaWidgetIntents.quickAddIntent(
                        context,
                        type = "expense",
                        account = account,
                        category = category,
                        requestCode = widgetId * 40 + 10,
                    ),
                )
                setOnClickPendingIntent(
                    R.id.amount_widget_income,
                    DadaWidgetIntents.quickAddIntent(
                        context,
                        type = "income",
                        account = account,
                        requestCode = widgetId * 40 + 11,
                    ),
                )
                setOnClickPendingIntent(
                    R.id.amount_widget_transfer,
                    DadaWidgetIntents.quickAddIntent(
                        context,
                        type = "transfer",
                        account = account,
                        toAccount = destination,
                        requestCode = widgetId * 40 + 12,
                    ),
                )
                setOnClickPendingIntent(
                    R.id.amount_widget_voice,
                    DadaWidgetIntents.quickAddIntent(
                        context,
                        type = type,
                        account = account,
                        category = category,
                        toAccount = destination,
                        voice = true,
                        requestCode = widgetId * 40 + 13,
                    ),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        appWidgetIds.forEach { DadaWidgetConfig.clear(context, it) }
    }
}
