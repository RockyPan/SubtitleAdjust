//
//  AppDelegate.h
//  SubtitleAdjust
//
//  Created by PanKyle on 15/2/28.
//  Copyright (c) 2015年 TGD. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSTextField *labCurrent;
@property (weak) IBOutlet NSTextField *labNext;
@property (weak) IBOutlet NSTextField *labIndex;
@property (weak) IBOutlet NSButton *btnSave;
@property (weak) IBOutlet NSButton *btnPlay;
@property (weak) IBOutlet NSButton *btnMoveForeward;
@property (weak) IBOutlet NSButton *btnMoveBackward;
@property (weak) IBOutlet NSButton *btnMerge;
@property (weak) IBOutlet NSButton *btnPreviews;
@property (weak) IBOutlet NSButton *btnNext;

- (IBAction)btnOpen:(id)sender;
- (IBAction)btnSave:(id)sender;
- (IBAction)btnPlay:(id)sender;
- (IBAction)btnMoveForeward:(id)sender;
- (IBAction)btnMoveBackward:(id)sender;
- (IBAction)btnMerge:(id)sender;
- (IBAction)btnPreview:(id)sender;
- (IBAction)btnNext:(id)sender;

@end

