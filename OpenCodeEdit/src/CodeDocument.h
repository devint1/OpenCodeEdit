#import <ChromiumTabs/ChromiumTabs.h>
#import <Scintilla/ScintillaView.h>

// This class represents a tab. In this example application a tab contains a
// simple scrollable text area.
@interface CodeDocument : CTTabContents <ScintillaNotificationProtocol> {
    NSTextView* tv;
    ScintillaView *sv;
	BOOL loaded;
	BOOL savePromptOpen;
	int currentLine;
    NSButton *eolButton;
}

-(void)setLoaded:(BOOL)isLoaded;
-(void)applyStyle;

@end
