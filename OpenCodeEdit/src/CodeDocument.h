#import <ChromiumTabs/ChromiumTabs.h>
#import <Scintilla/ScintillaView.h>
#import "FindBarController.h"
#import "ScintillaManager.h"

@class ScintillaManager;

@interface CodeDocument : CTTabContents {
    NSTextView* tv;
	BOOL savePromptOpen;
	int currentLine;
    NSButton *eolButton;
    ScintillaManager *sm;
	FindBarController *findBar;
}

@property (readwrite) BOOL loaded;
@property (readwrite) NSInteger language;
@property (readonly) ScintillaView *sv;

-(void)removeFindBar;
-(void)applyStyle;
-(void)findNext;
-(void)findPrevious;

@end

