#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (strong) NSWindow *window;

// Properties for the Book Library
@property (nonatomic, strong, nullable) NSWindow *libraryWindow;
@property (nonatomic, strong, nullable) NSTableView *libraryTableView;
@property (nonatomic, strong, nullable) NSSearchField *librarySearchField;
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *allBooks;
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *displayedBooks;

// Action method for opening a document
- (void)openDocument:(id)sender;
// You can add declarations for goToTop/goToBottom if you implement them
// - (void)goToTop:(id)sender;
// - (void)goToBottom:(id)sender;

@end

NS_ASSUME_NONNULL_END
