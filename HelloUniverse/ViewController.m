//
//  ViewController.m
//  HelloUniverse
//
//  Created by Shuffler on 2/12/13.
//  Copyright (c) 2013 Shuffler. All rights reserved.
//

#import "ViewController.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface ViewController ()
@property (nonatomic) ACAccountStore *accountStore;
@end

@implementation ViewController

@synthesize userID = _userID;

- (id)init
{
    self = [super init];
    if (self) {
        _accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)userHasAccessToTwitter
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

- (void)fetchTimelineForUser:(NSString *)username
{
    NSLog(@"fetchTimelineForUser");
    //  Step 0: Check that the user has local Twitter accounts
    if ([self userHasAccessToTwitter]) {
        NSLog(@"userHasAccessToTwitter");
        
        //  Step 1:  Obtain access to the user's Twitter accounts
        ACAccountType *twitterAccountType = [self.accountStore
                                             accountTypeWithAccountTypeIdentifier:
                                             ACAccountTypeIdentifierTwitter];
        [self.accountStore
         requestAccessToAccountsWithType:twitterAccountType
         options:NULL
         completion:^(BOOL granted, NSError *error) {
             NSLog(@"userHasAccessToTwitter.completion");
             if (granted) {
                 NSLog(@"userHasAccessToTwitter.granted");
                 //  Step 2:  Create a request
                 NSArray *twitterAccounts =
                 [self.accountStore accountsWithAccountType:twitterAccountType];
                 NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                               @"/1.1/statuses/user_timeline.json"];
                 NSDictionary *params = @{@"screen_name" : username,
                                          @"include_rts" : @"0",
                                          @"trim_user" : @"1",
                                          @"count" : @"1"};
                 SLRequest *request =
                 [SLRequest requestForServiceType:SLServiceTypeTwitter
                                    requestMethod:SLRequestMethodGET
                                              URL:url
                                       parameters:params];
                 
                 //  Attach an account to the request
                 [request setAccount:[twitterAccounts lastObject]];
                 
                 //  Step 3:  Execute the request
                 [request performRequestWithHandler:^(NSData *responseData,
                                                      NSHTTPURLResponse *urlResponse,
                                                      NSError *error) {
                     NSLog(@"userHasAccessToTwitter.after_execute");
                     if (responseData) {
                         NSLog(@"userHasAccessToTwitter.has_response_data");
                         if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                             NSLog(@"userHasAccessToTwitter.nice status code");
                             NSError *jsonError;
                             NSDictionary *timelineData =
                             [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:NSJSONReadingAllowFragments error:&jsonError];
                             
                             if (timelineData) {
                                 NSLog(@"Timeline Response: %@\n", timelineData);
                             }
                             else {
                                 // Our JSON deserialization went awry
                                 NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
                             }
                         }
                         else {
                             // The server did not respond successfully... were we rate-limited?
                             NSLog(@"The response status code is %d", urlResponse.statusCode);
                         }
                     }
                 }];
             }
             else {
                 // Access was not granted, or an error occurred
                 NSLog(@"%@", [error localizedDescription]);
             }
         }];
    } else {
        NSLog(@"no access to twitter");
    }
}


- (IBAction)changeGreeting:(id)sender {
    self.userID = self.textField.text;
    
    NSString *idString = self.userID;
    if ([idString length] == 0) {
        idString = @"Universe";
    }
    NSString *greeting = [[NSString alloc] initWithFormat:@"Hello, %@!", idString];
    self.label.text = greeting;
    
    
    [self fetchTimelineForUser:idString];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.textField) {
        [theTextField resignFirstResponder];
    }
    return YES;
}
@end