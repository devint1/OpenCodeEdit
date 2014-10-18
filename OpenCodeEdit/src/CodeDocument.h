#import <ChromiumTabs/ChromiumTabs.h>
#import <Scintilla/ScintillaView.h>
#import "ScintillaManager.h"

@class ScintillaManager;

@interface CodeDocument : CTTabContents {
    NSTextView* tv;
	BOOL savePromptOpen;
	int currentLine;
    NSButton *eolButton;
    ScintillaManager *sm;
}

@property (readwrite) BOOL loaded;
@property (readwrite) NSInteger language;
@property (readonly) ScintillaView *sv;

-(void)applyStyle;

@end

