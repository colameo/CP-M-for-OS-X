//
//  CPMBIOS.m
//  CPM for OS X
//
//  Created by Thomas Harte on 12/09/2012.
//  Copyright (c) 2012 Thomas Harte. All rights reserved.
//

#import "BIOS.h"
#import "TerminalView.h"

@implementation CPMBIOS
{
	CPMTerminalView *_terminalView;
	CPMProcessor *_processor;

	BOOL _isWaitingOnConsoleInput;
	BOOL _shouldEcho;
}

+ (id)BIOSWithTerminalView:(CPMTerminalView *)terminalView processor:(CPMProcessor *)processor
{
	return [[self alloc] initWithTerminalView:terminalView processor:processor];
}

- (id)initWithTerminalView:(CPMTerminalView *)terminalView processor:(CPMProcessor *)processor
{
	self = [super init];

	if(self)
	{
		// retain the terminal view and make this class the delegate
		_terminalView = terminalView;

		// also keep the processor
		_processor = processor;
	}

	return self;
}

- (CPMProcessorShouldBlock)makeCall:(int)callNumber
{
//	NSLog(@"BIOS %d", callNumber);
	switch(callNumber)
	{
		default:
			NSLog(@"unimplemented: bios call %d", callNumber);
		break;

		case 1:	return [self exitProgram];

		case 2:	// CONST
			// a = 0 means no character ready, 0xff means character ready
			[_processor set8bitCPMResult:[self consoleStatus]];
		return NO;

		case 4:	// CONOUT
			[self writeConsoleOutput:_processor.bcRegister&0xff];
		return NO;

		case 3: // CONIN
		{
			unichar nextInput = [_terminalView dequeueBufferedCharacter];
			if(nextInput)
			{
				[_processor set8bitCPMResult:nextInput];
				return NO;
			}
			else
			{
				_isWaitingOnConsoleInput = YES;
				return YES;
			}
		}
		return YES;
	}

	return NO;
}

- (uint8_t)dequeueCharacterIfAvailable
{
	return [_terminalView dequeueBufferedCharacter];
}

- (uint8_t)consoleStatus
{
	return [_terminalView hasCharacterToDequeue] ? 0xff : 0x00;
}

- (BOOL)readCharacterAndEcho
{
	uint8_t character = [self dequeueCharacterIfAvailable];
	if(character)
	{
		[self writeConsoleOutput:character];
		[_processor set8bitCPMResult:character];
		return NO;
	}

	_isWaitingOnConsoleInput = YES;
	_shouldEcho = YES;
	return YES;
}

- (void)writeConsoleOutput:(uint8_t)characer
{
	[_terminalView writeCharacter:characer];
}

- (void)terminalViewDidAddCharactersToBuffer:(CPMTerminalView *)terminalView
{
	if(_isWaitingOnConsoleInput)
	{
		unichar nextInput = [terminalView dequeueBufferedCharacter];
		[_processor set8bitCPMResult:nextInput];

		if(_shouldEcho)
		{
			[self writeConsoleOutput:nextInput];
		}

		[_processor unblock];
		_isWaitingOnConsoleInput = NO;
		_shouldEcho = NO;
	}
}

- (BOOL)exitProgram
{
	[self.delegate BIOSProgramDidExit:self];
	return YES;
}

@end
