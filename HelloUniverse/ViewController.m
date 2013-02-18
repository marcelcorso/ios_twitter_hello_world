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
#import "Base64.h"

@interface ViewController ()
@property (nonatomic,strong) ACAccountStore *accountStore;
@end

@implementation ViewController

@synthesize userID = _userID;

- (void)viewDidLoad
{
    _accountStore = [[ACAccountStore alloc] init];
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

- (void)resolveAccount: ( void ( ^ )(ACAccount *) )callback
{
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
                 callback([twitterAccounts lastObject]);
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

- (void)fetchFriends:(ACAccount *)account withCallback:( void ( ^ )(NSArray *) )callback
{
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
                    NSLog(@"Friends Response: %@\n", friendsData);
                    NSArray *friendIds = [friendsData valueForKey:@"ids"];
                    
                    callback(friendIds);
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

- (void) fetchUsers:(NSArray *)friendIds
{
     NSLog(@"fetchUsers: ");
    // request http://pre.shuffler.fm/users.json?twitter_id=4,5,6,7
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0), ^{
        NSString *joinedIds = [friendIds componentsJoinedByString:@","];
        NSMutableString *url = [NSMutableString stringWithFormat: @"http://shuffler:robot@pre.shuffler.fm/users.json?twitter_id=%@", joinedIds];
//        NSMutableString *url = [NSMutableString stringWithFormat: @"http://10.0.1.19:3000/users.json?twitter_id=%@", joinedIds];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: url]];
        
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", @"shuffler", @"a-very-nice-password"];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithWrapWidth:80]];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        
        NSError* error;
        NSURLResponse* response;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        NSLog(@"fetchUsers: data");
        
        if(data)
        {
            NSError *jsonError;
            NSArray *users =
            [NSJSONSerialization
             JSONObjectWithData:data
             options:NSJSONReadingAllowFragments error:&jsonError];
            
            NSLog(@"rendoreee");
            NSString* newStr = [[NSString alloc] initWithData:data
                                                      encoding:NSUTF8StringEncoding];
            NSLog(@"data: %@", newStr);
            
            [self renderUsers:users];
        }
        else
        {
            if (error)
            {
                NSLog(@"error %@",error);
            }
        }
    });
    
}

- (void)renderUsers:(NSArray *)users
{
    NSLog(@"render usors %@", users);
}

- (void)matchFriends
{
    // find out what twitter account to get the friends from
    [self resolveAccount:^(ACAccount *account) {
        if (account != nil) {
            
            // request N twitter friends
            [self fetchFriends:account withCallback:^(NSArray *friendIds) {

                // request the shuffler users with those twitter_ids
                [self fetchUsers:friendIds];
            }];
            
        } else {
            NSLog(@"NO ACCOUNTSS MAN");
        }
    }];
}

- (void)a: ( void ( ^ )(NSString *) )theBlock
{
    theBlock(@"bongo");
}

- (IBAction)changeGreeting:(id)sender {
    self.userID = self.textField.text;
    
    NSString *idString = self.userID;
    if ([idString length] == 0) {
        idString = @"Universe";
    }
    NSString *greeting = [[NSString alloc] initWithFormat:@"Hello, %@!", idString];
    self.label.text = greeting;
    
    [self matchFriends];

    [self a:^(NSString *msg){
        NSLog(@"bongo: %@", msg);
    }];

}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.textField) {
        [theTextField resignFirstResponder];
    }
    return YES;
}
@end
