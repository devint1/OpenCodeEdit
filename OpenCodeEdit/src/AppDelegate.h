#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"

@interface AppDelegate : NSDocumentController <NSApplicationDelegate> {
	PreferencesController *preferencesWindowController;
}

@property IBOutlet NSButton *eolButton;
@property IBOutlet NSMenu *languageMenu;

@end
