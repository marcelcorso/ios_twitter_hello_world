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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _accountStore = [[ACAccountStore alloc] init];
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

- (void)fetchFollowing {
    
    NSLog(@"fetchTimelineForUser");
    //  Step 0: Check that the user has local Twitter accounts
    if ([self userHasAccessToTwitter]) {
        NSLog(@"userHasAccessToTwitter");
        
        //  Step 1:  Obtain access to the user's Twitter accounts
        ACAccountType *twitterAccountType = [self.accountStore
                                             accountTypeWithAccountTypeIdentifier:
                                             ACAccountTypeIdentifierTwitter];
        NSLog(@"userHasAccessToTwitter wazzup???");
        [self.accountStore
         requestAccessToAccountsWithType:twitterAccountType
         options:NULL
         completion:^(BOOL granted, NSError *error) {
             NSLog(@"userHasAccessToTwitter.completion");
             if (granted) {
                 NSLog(@"userHasAccessToTwitter.granted");
                 //  Step 2:  Create a request
                 NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:twitterAccountType];
                 // TODO allow the user to select wich account he wants to use
                 ACAccount *account = [twitterAccounts lastObject];
                 NSString *screenName = [account username];
                 
                 NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/friends/ids.json"];
                 NSDictionary *params = @{@"screen_name" : screenName,
                                          @"count" : @"50000"};
                 SLRequest *request =
                 [SLRequest requestForServiceType:SLServiceTypeTwitter
                                    requestMethod:SLRequestMethodGET
                                              URL:url
                                       parameters:params];
                 
                 //  Attach an account to the request
                 [request setAccount: account];
                 
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
                             NSDictionary *followingData =
                             [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:NSJSONReadingAllowFragments error:&jsonError];
                             
                             if (followingData) {
                                 NSLog(@"Timeline Response: %@\n", followingData);
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

- (ACAccount *)resolveAccount
{
    __block ACAccount *account = nil;
    NSLog(@"fetchTimelineForUser");
    //  Step 0: Check that the user has local Twitter accounts
    if ([self userHasAccessToTwitter]) {
        NSLog(@"userHasAccessToTwitter");
        
        //  Step 1:  Obtain access to the user's Twitter accounts
        ACAccountType *twitterAccountType = [self.accountStore
                                             accountTypeWithAccountTypeIdentifier:
                                             ACAccountTypeIdentifierTwitter];
        NSLog(@"userHasAccessToTwitter wazzup???");
        [self.accountStore
         requestAccessToAccountsWithType:twitterAccountType
         options:NULL
         completion:^(BOOL granted, NSError *error) {
             NSLog(@"userHasAccessToTwitter.completion");
             if (granted) {
                 NSLog(@"userHasAccessToTwitter.granted");
                 //  Step 2:  Create a request
                 NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:twitterAccountType];
                 
                 
                 // TODO allow the user to select wich account he wants to use
                 account = [twitterAccounts lastObject];
             }
             else {
                 // Access was not granted, or an error occurred
                 NSLog(@"%@", [error localizedDescription]);
             }
         }];
    } else {
        NSLog(@"no access to twitter");
    }
    
    return account;
}

- (NSArray *)fetchFriends:(ACAccount *)account
{
    __block NSArray *friendIds = [NSArray array];
    NSString *screenName = [account username];
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/friends/ids.json"];
    NSDictionary *params = @{@"screen_name" : screenName,
                             @"count" : @"50000"};
    SLRequest *request =
    [SLRequest requestForServiceType:SLServiceTypeTwitter
                       requestMethod:SLRequestMethodGET
                                 URL:url
                          parameters:params];
    
    //  Attach an account to the request
    [request setAccount: account];
    
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
                NSDictionary *friendsData =
                [NSJSONSerialization
                 JSONObjectWithData:responseData
                 options:NSJSONReadingAllowFragments error:&jsonError];
                
                if (friendsData) {
                    NSLog(@"Timeline Response: %@\n", friendsData);
                    friendIds = [friendsData valueForKey:@"friends"];
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

    return friendIds;
}

- (NSArray *) fetchUsers:(NSArray *)friendIds
{
    NSArray *matchedUsers = [NSArray array];
    // request http://pre.shuffler.fm/users.json?twitter_id=4,5,6,7
    
}


- (void)matchFriends
{
    // find out what twitter account to get the friends from
    ACAccount *account = [self resolveAccount];
    // request N twitter friends
    NSArray *friendIds = [self fetchFriends:account];
    // request the shuffler users with those twitter_ids
    NSArray *matchedUsers = [self fetchUsers:friendIds];
}

- (IBAction)changeGreeting:(id)sender {
    self.userID = self.textField.text;
    
    NSString *idString = self.userID;
    if ([idString length] == 0) {
        idString = @"Universe";
    }
    NSString *greeting = [[NSString alloc] initWithFormat:@"Hello, %@!", idString];
    self.label.text = greeting;
    
    
    // [self fetchTimelineForUser:idString];
    
    
    [self matchFriends];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.textField) {
        [theTextField resignFirstResponder];
    }
    return YES;
}
@end
