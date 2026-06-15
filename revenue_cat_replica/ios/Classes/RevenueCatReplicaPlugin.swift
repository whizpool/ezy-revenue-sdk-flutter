import Flutter
import UIKit
import StoreKit

public class RevenueCatReplicaPlugin: NSObject, FlutterPlugin, SKProductsRequestDelegate, SKPaymentTransactionObserver {
  private var pendingResult: FlutterResult?
  private var getProductsResult: FlutterResult?
  private var productsRequest: SKProductsRequest?
  private var currentAppUserId: String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "revenue_cat_replica", binaryMessenger: registrar.messenger())
    let instance = RevenueCatReplicaPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    SKPaymentQueue.default().add(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getCountryCode":
      let region = Locale.current.regionCode
      result(region?.uppercased())
    case "purchaseProduct":
      if let args = call.arguments as? [String: Any],
         let productIdentifier = args["productIdentifier"] as? String {
          let appUserId = args["appUserId"] as? String
          self.startPurchase(productIdentifier: productIdentifier, appUserId: appUserId, result: result)
      } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Product identifier is required", details: nil))
      }
    case "getAppVersion":
      let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
      result(version ?? "unknown")
    case "getProducts":
      if let args = call.arguments as? [String: Any],
         let productIdentifiers = args["productIdentifiers"] as? [String] {
          self.fetchProducts(productIdentifiers: productIdentifiers, result: result)
      } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Product identifiers are required", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startPurchase(productIdentifier: String, appUserId: String?, result: @escaping FlutterResult) {
    if self.pendingResult != nil {
      result(FlutterError(code: "BUSY", message: "A purchase is already in progress", details: nil))
      return
    }
    self.pendingResult = result
    self.currentAppUserId = appUserId

    let productIdentifiers = Set([productIdentifier])
    productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
    productsRequest?.delegate = self
    productsRequest?.start()
  }

  private func fetchProducts(productIdentifiers: [String], result: @escaping FlutterResult) {
    self.getProductsResult = result
    let identifiers = Set(productIdentifiers)
    productsRequest = SKProductsRequest(productIdentifiers: identifiers)
    productsRequest?.delegate = self
    productsRequest?.start()
  }

  // MARK: - SKProductsRequestDelegate
  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    if let productsResult = self.getProductsResult {
      let productsList = response.products.map { product -> [String: Any] in
        let priceAmountMicros = Int64(truncating: product.price.multiplying(by: 1000000) as NSDecimalNumber)
        return [
          "identifier": product.productIdentifier,
          "title": product.localizedTitle,
          "description": product.localizedDescription,
          "priceAmountMicros": priceAmountMicros,
          "priceCurrencyCode": product.priceLocale.currencyCode ?? ""
        ]
      }
      DispatchQueue.main.async {
        productsResult(productsList)
        self.getProductsResult = nil
      }
      return
    }

    if let product = response.products.first {
      let payment = SKMutablePayment(product: product)
      if let appUserId = self.currentAppUserId {
          payment.applicationUsername = appUserId
      }
      SKPaymentQueue.default().add(payment)
    } else {
      DispatchQueue.main.async {
        self.pendingResult?(false)
        self.pendingResult = nil
      }
    }
  }

  public func request(_ request: SKRequest, didFailWithError error: Error) {
    DispatchQueue.main.async {
      if let productsResult = self.getProductsResult {
        productsResult(FlutterError(code: "STORE_REQUEST_FAILED", message: error.localizedDescription, details: nil))
        self.getProductsResult = nil
      } else {
        self.pendingResult?(FlutterError(code: "STORE_REQUEST_FAILED", message: error.localizedDescription, details: nil))
        self.pendingResult = nil
      }
    }
  }

  // MARK: - SKPaymentTransactionObserver
  public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        SKPaymentQueue.default().finishTransaction(transaction)
        finish(success: true)
      case .failed:
        SKPaymentQueue.default().finishTransaction(transaction)
        finish(success: false)
      case .restored:
        SKPaymentQueue.default().finishTransaction(transaction)
        finish(success: true)
      case .deferred, .purchasing:
        break
      @unknown default:
        break
      }
    }
  }

  private func finish(success: Bool) {
    DispatchQueue.main.async {
      self.pendingResult?(success)
      self.pendingResult = nil
    }
  }

  deinit {
      SKPaymentQueue.default().remove(self)
  }
}
