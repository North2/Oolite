/*

OOJavaScriptConsoleController.h

JavaScript debugging console for Oolite.


Oolite Debug OXP

Copyright (C) 2007 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import <Cocoa/Cocoa.h>
#import "OOWeakReference.h"

@class OOScript, OOTextFieldHistoryManager;


@interface OOJavaScriptConsoleController: OOWeakRefObject
{
	IBOutlet NSWindow					*consoleWindow;
	IBOutlet NSTextView					*consoleTextView;
	IBOutlet NSTextField				*consoleInputField;
	IBOutlet OOTextFieldHistoryManager	*inputHistoryManager;
	
	NSScrollView						*_consoleScrollView;
	
	NSFont								*_baseFont,
										*_boldFont;
	
	NSDictionary						*_configFromOXPs;	// Settings from jsConsoleConfig.plist
	NSMutableDictionary					*_configOverrides;	// Settings from preferences, modifiable through JS.
	
	// Caches
	NSMutableDictionary					*_fgColors,
										*_bgColors,
										*_sourceFiles;
	
	OOScript							*_script;
	struct JSObject						*_jsSelf;
	
	BOOL								_showOnWarning,
										_showOnError,
										_showOnLog;
}

- (IBAction)showConsole:sender;
- (IBAction)toggleShowOnLog:sender;
- (IBAction)toggleShowOnWarning:sender;
- (IBAction)toggleShowOnError:sender;
- (IBAction)consolePerformCommand:sender;

// Perform a JS command as though entered at the console, including echoing.
- (void)performCommand:(NSString *)command;

- (void)appendLine:(id)string colorKey:(NSString *)colorKey;
- (void)clear;

- (id)configurationValueForKey:(NSString *)key;
- (id)configurationValueForKey:(NSString *)key class:(Class)class defaultValue:(id)value;
- (long long)configurationIntValueForKey:(NSString *)key defaultValue:(long long)value;
- (void)setConfigurationValue:(id)value forKey:(NSString *)key;
- (NSArray *)configurationKeys;

@end
