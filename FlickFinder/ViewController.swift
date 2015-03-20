//
//  ViewController.swift
//  FlickFinder
//
//  Created by Antonio Maradiaga on 19/03/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit

let SECRET = "04773b7f7a6c1710"

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "60d79188f8d90a27d111b22a803d7ecf"
let GALLERY_ID = "66911286-72157647263150569" //"5704-72157622566655097" Sleeping in the Library
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

class ViewController: UIViewController {

    @IBOutlet weak var flickTitleLabel: UILabel!
    @IBOutlet weak var flickLongitudeText: UITextField!
    @IBOutlet weak var flickLatitudeText: UITextField!
    @IBOutlet weak var flickSearchTermText: UITextField!
    @IBOutlet weak var flickImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardNotification:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardNotification:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:
            UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:
            UIKeyboardWillHideNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func searchByTerm(sender: AnyObject) {
        let extraParams: [String:String] = [
            "text": flickSearchTermText.text
        ]
        getImageFromFlickr(extraParams)
    }

    @IBAction func searchByLatLon(sender: UIButton) {
        let extraParams: [String:String] = [
            "lat": flickLatitudeText.text,
            "lon": flickLongitudeText.text
        ]
        getImageFromFlickr(extraParams)
    }
    
    func getImageFromFlickr(extraParams: [String:String]) {
        
        /* 2 - API method arguments */
        var methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        for paramName in extraParams.keys {
            methodArguments[paramName] = extraParams[paramName]
        }
        
        
        /* 3 - Initialize session and url */
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* 4 - Initialize task for getting data */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            var errorText: String?
            
            if let error = downloadError? {
                errorText = "Could not complete the request \(error)"
                println(errorText)
                
            } else {
                /* 5 - Success! Parse the data */
                var parsingError: NSError? = nil
                let parsedResult: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
                
                if let photosDictionary = parsedResult["photos"] as? NSDictionary {
                    if let totalPhotos = photosDictionary["total"] as? String {
                        if totalPhotos.toInt() > 0 {
                            println("totalPhotos: \(totalPhotos)")
                            if let photoArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                
                                /* 6 - Grab a single, random image */
                                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                                let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
                                
                                /* 7 - Get the image url and title */
                                let photoTitle = photoDictionary["title"] as? String
                                let imageUrlString = photoDictionary["url_m"] as? String
                                let imageURL = NSURL(string: imageUrlString!)
                                
                                /* 8 - If an image exists at the url, set the image and title */
                                if let imageData = NSData(contentsOfURL: imageURL!) {
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.flickImageView.image = UIImage(data: imageData)
                                        self.flickTitleLabel.text = photoTitle
                                    })
                                } else {
                                    errorText = "Image does not exist at \(imageURL)"
                                    println(errorText)
                                }
                            } else {
                                errorText = "Cant find key 'photo' in \(photosDictionary)"
                                println(errorText)
                            }
                        }else {
                            errorText = "No photos exists for your current search."
                        }
                    }
                } else {
                    errorText = "Cant find key 'photos' in \(parsedResult)"
                    println(errorText)
                }
            }
            if(errorText != nil){
                dispatch_async(dispatch_get_main_queue(), {
                    self.flickTitleLabel.text = errorText
                    self.flickImageView.image = nil
                })
            }
            
        }
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* FIX: Replace spaces with '+' */
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
            /* Append it */
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    var isKeyboardUp: Bool = false
    
    func handleKeyboardNotification(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue().height
        
        if(notification.name == UIKeyboardDidShowNotification && isKeyboardUp == false) {
            self.view.frame.origin.y -= keyboardHeight
            isKeyboardUp = true
        } else if(notification.name == UIKeyboardWillHideNotification && isKeyboardUp == true) {
            self.view.frame.origin.y += keyboardHeight
            isKeyboardUp = false
        }
        
        UIView.commitAnimations()
    }
    
}

