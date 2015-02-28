//
//  AppDelegate.m
//  SubtitleAdjust
//
//  Created by PanKyle on 15/2/28.
//  Copyright (c) 2015年 TGD. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (nonatomic, copy) NSString *filename;

@end

NSMutableArray *_subtitles;
unsigned int _index;
NSSound *_player;
NSTimer *_timer;
bool _doesEdit;
bool _fileOpened;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)openMP3File:(NSURL *)mp3Filename {
    [self.window setTitle:[NSString stringWithFormat:@"SubtitleAdjust - %@", mp3Filename.lastPathComponent]];
    NSURL * lrcFilename = [mp3Filename.URLByDeletingPathExtension URLByAppendingPathExtension:@"lrc"];
    NSLog(@"%@", mp3Filename);
    NSLog(@"%@", lrcFilename);
    
    [self loadLrc:lrcFilename];
    
    _player = [[NSSound alloc] initWithContentsOfURL:mp3Filename byReference:YES];
    
    _index = 1;
    _fileOpened = true;
    [self initStatus];
    
    [_player play];
    [_player pause];
}

- (void)loadLrc:(NSURL*)lrcFilename {
    NSError * error = nil;
    NSString * strContent = [NSString stringWithContentsOfURL:lrcFilename encoding:NSASCIIStringEncoding error:&error];
    
    //PK 分行
    NSArray * content = [strContent componentsSeparatedByString:@"\n"];
    
    NSLog(@"%@", content);
    
    if (NULL == _subtitles) {
        _subtitles = [[NSMutableArray alloc] init];
    } else {
        [_subtitles removeAllObjects];
    }
    
    [content enumerateObjectsUsingBlock:^(NSString * item, NSUInteger idx, BOOL *stop) {
        NSDateFormatter * df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"mm:ss.SS"];
        NSDate * begin = [df dateFromString:@"00:00.00"];
        if ([item length] < 11) return;
        if (([item characterAtIndex:0] == '[') && ([item characterAtIndex:9] == ']')) {
            NSDate * date = [df dateFromString:[item substringWithRange:NSMakeRange(1,8)]];
            NSTimeInterval interval = [date timeIntervalSinceDate:begin];
            
            [_subtitles addObject:
             @{@"time" : [NSNumber numberWithDouble:interval],
               @"subtitle" : [item substringFromIndex:10]}];
        }
    }];
    
    NSLog(@"%@", _subtitles);
}

- (void)initStatus {
    bool lastSentence = _fileOpened ? _index == _subtitles.count : false;
    if (_fileOpened) {
        self.labCurrent.stringValue = _subtitles[_index - 1][@"subtitle"];
        self.labNext.stringValue = lastSentence ? @"" : _subtitles[_index][@"subtitle"];
    }

    self.labIndex.stringValue = _fileOpened ? [NSString stringWithFormat:@"%d/%lu", _index, (unsigned long)_subtitles.count] : @"-/-";
    
    [self.btnSave setEnabled: _fileOpened && _doesEdit];
    [self.btnPlay setEnabled:_fileOpened];
    [self.btnMoveForeward setEnabled:_fileOpened];
    [self.btnMoveBackward setEnabled:_fileOpened];
    [self.btnMerge setEnabled:_fileOpened];
    [self.btnPreviews setEnabled:_fileOpened && _index != 1];
    //PK 只需要到倒数第二句
    [self.btnNext setEnabled:_fileOpened && _index != _subtitles.count - 1];
}

- (IBAction)btnOpen:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setPrompt: @"play"];
    [panel setAllowedFileTypes:@[@"mp3"]];
    [panel setAllowsMultipleSelection:NO];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (NSFileHandlingPanelOKButton == result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self openMP3File:panel.URL];
            });
        }
    }];
}

- (IBAction)btnSave:(id)sender {
}

- (IBAction)btnPlay:(id)sender {
    
}

- (IBAction)btnMoveForeward:(id)sender {
    
}

- (IBAction)btnMoveBackward:(id)sender {
    
}

- (IBAction)btnMerge:(id)sender {
    
}

- (IBAction)btnPreview:(id)sender {
}

- (IBAction)btnNext:(id)sender {
}

@end
