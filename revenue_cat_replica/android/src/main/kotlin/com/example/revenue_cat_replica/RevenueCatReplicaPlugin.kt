package com.example.revenue_cat_replica

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Locale

/** RevenueCatReplicaPlugin */
class RevenueCatReplicaPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PurchasesUpdatedListener {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var billingClient: BillingClient? = null
    private var pendingResult: Result? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "revenue_cat_replica")
        channel.setMethodCallHandler(this)

        billingClient = BillingClient.newBuilder(context!!)
            .setListener(this)
            .enablePendingPurchases()
            .build()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        println("Method call: ${call.method}, arguments: ${call.arguments}")
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "getCountryCode" -> {
                val country = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                    Locale.getDefault(Locale.Category.FORMAT).country
                } else {
                    Locale.getDefault().country
                }
                result.success(country?.uppercase())
            }
            "getAppVersion" -> {
                try {
                    val pInfo = context?.packageManager?.getPackageInfo(context?.packageName ?: "", 0)
                    result.success(pInfo?.versionName)
                } catch (e: Exception) {
                    result.success("unknown")
                }
            }
            "purchaseProduct" -> {
                val productIdentifier = call.argument<String>("productIdentifier")
                val appUserId = call.argument<String>("appUserId")
                if (productIdentifier == null) {
                    println("Error: productIdentifier is null")
                    result.error("ERROR", "Product identifier is null", null)
                    return
                }
                pendingResult = result
                startPurchaseFlow(productIdentifier, appUserId)
            }
            "getProducts" -> {
                val productIdentifiers = call.argument<List<String>>("productIdentifiers")
                if (productIdentifiers == null) {
                    result.error("ERROR", "Product identifiers are null", null)
                    return
                }
                fetchProducts(productIdentifiers, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startPurchaseFlow(productId: String, appUserId: String?) {
        println("Starting purchase flow for $productId (user: $appUserId)")
        billingClient?.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                println("Billing setup finished: ${billingResult.responseCode}, ${billingResult.debugMessage}")
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    queryProductAndLaunchFlow(productId, appUserId)
                } else {
                    println("Billing setup failed")
                    pendingResult?.success(false)
                    pendingResult = null
                }
            }

            override fun onBillingServiceDisconnected() {
                println("Billing service disconnected")
            }
        })
    }

    private fun fetchProducts(productIds: List<String>, result: Result) {
        billingClient?.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    val products = mutableListOf<Map<String, Any>>()
                    
                    val subsToQuery = productIds.map {
                        QueryProductDetailsParams.Product.newBuilder()
                            .setProductId(it)
                            .setProductType(BillingClient.ProductType.SUBS)
                            .build()
                    }
                    val inAppToQuery = productIds.map {
                        QueryProductDetailsParams.Product.newBuilder()
                            .setProductId(it)
                            .setProductType(BillingClient.ProductType.INAPP)
                            .build()
                    }

                    val querySubsParams = QueryProductDetailsParams.newBuilder().setProductList(subsToQuery).build()
                    val queryInAppParams = QueryProductDetailsParams.newBuilder().setProductList(inAppToQuery).build()

                    billingClient?.queryProductDetailsAsync(querySubsParams) { res1, subsList ->
                        if (res1.responseCode == BillingClient.BillingResponseCode.OK) {
                            subsList.forEach { details ->
                                val productMap = mutableMapOf<String, Any>()
                                productMap["identifier"] = details.productId
                                productMap["title"] = details.title
                                productMap["description"] = details.description
                                details.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.let {
                                    productMap["priceAmountMicros"] = it.priceAmountMicros
                                    productMap["priceCurrencyCode"] = it.priceCurrencyCode
                                }
                                products.add(productMap)
                            }
                        }
                        
                        billingClient?.queryProductDetailsAsync(queryInAppParams) { res2, inAppList ->
                            if (res2.responseCode == BillingClient.BillingResponseCode.OK) {
                                inAppList.forEach { details ->
                                    val productMap = mutableMapOf<String, Any>()
                                    productMap["identifier"] = details.productId
                                    productMap["title"] = details.title
                                    productMap["description"] = details.description
                                    details.oneTimePurchaseOfferDetails?.let {
                                        productMap["priceAmountMicros"] = it.priceAmountMicros
                                        productMap["priceCurrencyCode"] = it.priceCurrencyCode
                                    }
                                    products.add(productMap)
                                }
                            }
                            result.success(products)
                        }
                    }
                } else {
                    result.error("BILLING_ERROR", "Billing setup failed: ${billingResult.responseCode}", null)
                }
            }

            override fun onBillingServiceDisconnected() {
                // Connection lost
            }
        })
    }

    private fun queryProductAndLaunchFlow(productId: String, appUserId: String?) {
        println("Querying product details for $productId")
        val querySubsParams = QueryProductDetailsParams.newBuilder()
            .setProductList(
                listOf(
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(productId)
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build()
                )
            )
            .build()

        billingClient?.queryProductDetailsAsync(querySubsParams) { billingResult, productDetailsList ->
            println("Subs query result: ${billingResult.responseCode}, size: ${productDetailsList.size}")
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && productDetailsList.isNotEmpty()) {
                launchBillingFlow(productDetailsList[0], appUserId)
            } else {
                // If not found in SUBS, try INAPP
                val queryInAppParams = QueryProductDetailsParams.newBuilder()
                    .setProductList(
                        listOf(
                            QueryProductDetailsParams.Product.newBuilder()
                                .setProductId(productId)
                                .setProductType(BillingClient.ProductType.INAPP)
                                .build()
                        )
                    )
                    .build()

                billingClient?.queryProductDetailsAsync(queryInAppParams) { inAppResult, inAppDetailsList ->
                    println("In-app query result: ${inAppResult.responseCode}, size: ${inAppDetailsList.size}")
                    if (inAppResult.responseCode == BillingClient.BillingResponseCode.OK && inAppDetailsList.isNotEmpty()) {
                        launchBillingFlow(inAppDetailsList[0], appUserId)
                    } else {
                        println("Product not found in SUBS or INAPP")
                        pendingResult?.success(false)
                        pendingResult = null
                    }
                }
            }
        }
    }

    private fun launchBillingFlow(productDetails: ProductDetails, appUserId: String?) {
        println("Launching billing flow for ${productDetails.productId} with user $appUserId")
        val productDetailsParamsBuilder = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(productDetails)

        if (productDetails.productType == BillingClient.ProductType.SUBS) {
            val offerDetails = productDetails.subscriptionOfferDetails
            if (!offerDetails.isNullOrEmpty()) {
                println("Setting offer token: ${offerDetails[0].offerToken}")
                productDetailsParamsBuilder.setOfferToken(offerDetails[0].offerToken)
            } else {
                println("No subscription offer details found for SUBS product")
            }
        }

        val billingFlowParamsBuilder = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(productDetailsParamsBuilder.build()))

        if (appUserId != null) {
            billingFlowParamsBuilder.setObfuscatedAccountId(appUserId)
        }

        val billingFlowParams = billingFlowParamsBuilder.build()

        activity?.let {
            val result = billingClient?.launchBillingFlow(it, billingFlowParams)
            println("Launch billing flow result: ${result?.responseCode}, ${result?.debugMessage}")
        } ?: run {
            println("Error: Activity is null, cannot launch billing flow")
            pendingResult?.error("NO_ACTIVITY", "Activity is null", null)
            pendingResult = null
        }
    }

    override fun onPurchasesUpdated(billingResult: BillingResult, purchases: List<Purchase>?) {
        println("onPurchasesUpdated: ${billingResult.responseCode}, ${billingResult.debugMessage}")
        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            println("Purchase successful")
            pendingResult?.success(true)
        } else if (billingResult.responseCode == BillingClient.BillingResponseCode.USER_CANCELED) {
            println("Purchase user canceled")
            pendingResult?.success(false)
        } else {
            println("Purchase failed with code: ${billingResult.responseCode}")
            pendingResult?.success(false)
        }
        pendingResult = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
        billingClient?.endConnection()
    }

    // ActivityAware methods
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
