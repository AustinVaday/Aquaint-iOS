import Foundation
import Stripe
import AWSLambda

class MyAPIClient: NSObject, STPBackendAPIAdapter {
  
  static let sharedClient = MyAPIClient()
  let session: NSURLSession
  var baseURLString: String? = nil
  var defaultSource: STPCard? = nil
  var sources: [STPCard] = []
  var username: String!
  
  override init() {
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.timeoutIntervalForRequest = 5
    self.session = NSURLSession(configuration: configuration)
    
    username = getCurrentCachedUser()
  
    super.init()
    }
  
  func completeSubscription(result: STPPaymentResult, planOption: String, completion: STPErrorBlock)
  {
    let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
    //let parameters = ["action":"createSubscription", "source": result.source.stripeID, "amount": amount, "currency": currency]
    let parameters = ["action":"createSubscription", "target": username, "plan": planOption]
    
    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil
      {
        print("Result task for createSubscription is: ", resultTask.result!)
        completion(nil)
      }
      else {
        completion(resultTask.error)
      }
      
      return nil
    }

  }
  
  func retrieveCustomer(completion: STPCustomerCompletionBlock) {
    let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
    let parameters = ["action":"getPaymentCustomerObject", "target": username]
    
    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil
      {
        print("Result task for getPaymentCustomerObject is: ", resultTask.result!)
        let customer = STPCustomerDeserializer(JSONResponse: resultTask.result!).customer
        completion(customer, nil)
      }
      else {
        completion(nil, resultTask.error)
      }
      
      return nil
    }

  }
  
  func attachSourceToCustomer(source: STPSource, completion: STPErrorBlock) {
    let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
    let parameters = ["action":"attachPaymentSourceToCustomerObject", "target": username, "source": source.stripeID]
    
    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil
      {
        print("Result task for attachPaymentSourceToCustomerObject is: ", resultTask.result!)
        completion(nil)
      }
      else {
        completion(resultTask.error)
      }
      
      return nil
    }
    
  }
  
  func selectDefaultCustomerSource(source: STPSource, completion: STPErrorBlock) {
    let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
    let parameters = ["action":"selectDefaultPaymentSource", "target": username, "default_source": source.stripeID]
    
    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil
      {
        print("Result task for selectDefaultPaymentSource is: ", resultTask.result!)
        completion(nil)
      }
      else {
        completion(resultTask.error)
      }
      
      return nil
    }

  }

}