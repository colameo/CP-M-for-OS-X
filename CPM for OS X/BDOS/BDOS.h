//
//  BDOS.h
//  CPM for OS X
//
//  Created by Thomas Harte on 12/09/2012.
//  Copyright (c) 2012 Thomas Harte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Processor.h"
#import "TerminalView.h"

@class CPMTerminalView;

@interface CPMBDOS : NSObject <CPMProcessorDelegate, CPMTerminalViewDelegate>

+ (id)BDOSWithContentsOfURL:(NSURL *)URL terminalView:(CPMTerminalView *)terminalView;
+ (id)BDOSWithData:(NSData *)data terminalView:(CPMTerminalView *)terminalView;

- (void)runForTimeInterval:(NSTimeInterval)interval;
- (void)runForNumberOfInstructions:(NSUInteger)numberOfInstructions;

@property (nonatomic, readonly) BOOL didBlock;
@property (nonatomic, strong) NSString *basePath;

@end
