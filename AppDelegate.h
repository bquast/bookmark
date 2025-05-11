#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSWindow *window;

// Action method for opening a document
- (void)openDocument:(id)sender;
// You can add declarations for goToTop/goToBottom if you implement them
// - (void)goToTop:(id)sender;
// - (void)goToBottom:(id)sender;

@end
