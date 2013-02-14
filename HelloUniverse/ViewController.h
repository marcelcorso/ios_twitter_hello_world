//
//  ViewController.h
//  HelloUniverse
//
//  Created by Shuffler on 2/12/13.
//  Copyright (c) 2013 Shuffler. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITextFieldDelegate>
- (IBAction)changeGreeting:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (copy, nonatomic) NSString *userID;

@end
