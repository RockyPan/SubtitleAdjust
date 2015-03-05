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

//@property (nonatomic, copy) NSString *lrcFilename;

@end

NSMutableArray *_subtitles;
unsigned int _index;
NSSound *_player;
NSTimer *_timer;
bool _doesEdit;
bool _fileOpened;
NSURL *_lrcURL;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    _player = NULL;
    _timer = NULL;
    _subtitles = NULL;
    _doesEdit = false;
    _fileOpened = false;
    _index = 1;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)openMP3File:(NSURL *)mp3Filename {
    [self.window setTitle:[NSString stringWithFormat:@"SubtitleAdjust - %@", mp3Filename.lastPathComponent]];
    NSURL * lrcFilename = [mp3Filename.URLByDeletingPathExtension URLByAppendingPathExtension:@"lrc"];
    _lrcURL = lrcFilename;
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
             [@{@"time" : [NSNumber numberWithDouble:interval],
               @"subtitle" : [item substringFromIndex:10]} mutableCopy]];
        }
    }];
    
    //NSLog(@"%@", _subtitles);
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

- (void)playDone {
    [_player pause];
}

- (void)playFrom:(NSTimeInterval)start to:(NSTimeInterval)end {
    [_player pause];
    [_timer invalidate];
    [_player setCurrentTime:start];
    NSTimeInterval duration = end - start;
    _timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(playDone) userInfo:nil repeats:NO];
    [_player resume];
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
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"mm:ss:SS"];
    NSDate *begin = [df dateFromString:@"00:00:00"];
    NSMutableString *content = [[NSMutableString alloc] init];
//    [_subtitles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        NSMutableDictionary * item = (NSMutableDictionary*)obj;
//        NSDate * date = [begin dateByAddingTimeInterval:((NSNumber*)(item[@"time"])).doubleValue];
//        [content appendFormat:@"[%@]%@\n", [df stringFromDate:date], item[@"subtitle"]];
//        NSString * line = [NSString stringWithFormat:@"[%@]%@", [df stringFromDate:date], item[@"subtitle"] ];
//        NSLog(@"%@", line);
//    }];
    for (NSDictionary *obj in _subtitles) {
        NSDate *date = [begin dateByAddingTimeInterval:((NSNumber*)(obj[@"time"])).doubleValue];
        [content appendFormat:@"[%@]%@\n", [df stringFromDate:date], obj[@"subtitle"]];
    }
    [content writeToURL:_lrcURL atomically:YES encoding:NSASCIIStringEncoding error:nil];
}

- (IBAction)btnPlay:(id)sender {
    //PK 因为在btnNext中做了处理，这里不用再判断index会越界
    NSTimeInterval curStart = ((NSNumber *)(_subtitles[_index - 1][@"time"])).doubleValue;
    NSTimeInterval curEnd = ((NSNumber *)(_subtitles[_index][@"time"])).doubleValue;
    
    [self playFrom:curStart to:curEnd];
}

- (IBAction)btnMoveForeward:(id)sender {
    NSNumber *old = _subtitles[_index][@"time"];
    _subtitles[_index][@"time"] = [NSNumber numberWithDouble:old.doubleValue + 0.1];
    _doesEdit = true;
    [self initStatus];
}

- (IBAction)btnMoveBackward:(id)sender {
    NSNumber *old = _subtitles[_index][@"time"];
    _subtitles[_index][@"time"] = [NSNumber numberWithDouble:(old.doubleValue - 0.1)];
    _doesEdit = true;
    [self initStatus];
}

- (IBAction)btnMerge:(id)sender {
    
}

- (IBAction)btnPreview:(id)sender {
}

- (IBAction)btnNext:(id)sender {
    ++_index;
    [self initStatus];
}

- (IBAction)btnPlayCur:(id)sender {
    //PK 播放当前名字的最后5秒，如果本句小于5秒就插整句
    //PK 因为在btnNext中做了处理，这里不用再判断index会越界
    NSTimeInterval curStart = ((NSNumber *)(_subtitles[_index - 1][@"time"])).doubleValue;
    NSTimeInterval curEnd = ((NSNumber *)(_subtitles[_index][@"time"])).doubleValue;
    NSTimeInterval curPos = curEnd - 3.0;
    curPos = curPos < curStart ? curStart : curPos;
    
    [self playFrom:curPos to:curEnd];
}

- (IBAction)btnPlayNext:(id)sender {
    NSTimeInterval curStart = ((NSNumber *)(_subtitles[_index][@"time"])).doubleValue;
    NSTimeInterval curEnd = 0.0;
    //PK 如果这部分已经是最后一句，结束部分要特殊处理
    if (_index + 1 == _subtitles.count) {
        curEnd = _player.duration;
    } else {
        curEnd = ((NSNumber *)(_subtitles[_index + 1][@"time"])).doubleValue;
    }
    NSTimeInterval curPos = curStart + 3.0;
    curPos = curPos > curEnd ? curEnd : curPos;
    
    [self playFrom:curStart to:curPos];
}

@end
