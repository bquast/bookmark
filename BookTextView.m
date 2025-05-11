#import "BookTextView.h"
#import <Carbon/Carbon.h> // For kVK_* key codes

@implementation BookTextView

- (void)keyDown:(NSEvent *)event {
    BOOL pageKeyHandled = NO;
    
    // Ensure we have an enclosing scroll view and its clip view
    if (!self.enclosingScrollView || !self.enclosingScrollView.contentView) {
        [super keyDown:event];
        return;
    }
    
    NSClipView *clipView = self.enclosingScrollView.contentView;
    CGFloat pageHeight = clipView.bounds.size.height;
    NSPoint currentOrigin = clipView.bounds.origin;
    CGFloat documentHeight = self.frame.size.height; // Height of the entire text document

    // Check if document is smaller than or equal to a page, no paging needed beyond arrows for selection
    if (documentHeight <= pageHeight) {
        [super keyDown:event]; // Allow normal arrow key behavior for selection
        return;
    }

    switch (event.keyCode) {
        case kVK_RightArrow:
        case kVK_DownArrow:
            currentOrigin.y += pageHeight;
            // Ensure we don't scroll beyond the document.
            // If the next scroll position would leave less than a full page at the bottom,
            // scroll to show the very end of the document.
            if (currentOrigin.y + pageHeight > documentHeight) {
                currentOrigin.y = documentHeight - pageHeight;
            }
            pageKeyHandled = YES;
            break;
            
        case kVK_LeftArrow:
        case kVK_UpArrow:
            currentOrigin.y -= pageHeight;
            if (currentOrigin.y < 0) {
                currentOrigin.y = 0; // Don't scroll above the top
            }
            pageKeyHandled = YES;
            break;
            
        default:
            // For any other key, use the default NSTextView behavior
            [super keyDown:event];
            return; // Exit early
    }

    if (pageKeyHandled) {
        // Make sure origin.y is within valid bounds after calculation
        if (currentOrigin.y < 0) currentOrigin.y = 0;
        if (currentOrigin.y > documentHeight - pageHeight) {
             currentOrigin.y = documentHeight - pageHeight;
        }
        
        // Animate the scroll for a smoother page turn feel
        // If you prefer an instant jump, just call [clipView setBoundsOrigin:currentOrigin];
        [[clipView animator] setBoundsOrigin:currentOrigin];
        
        // Optional: If not using animator and setBoundsOrigin directly, you might need:
        // [self.enclosingScrollView reflectScrolledClipView:clipView];
    }
    // Do not call [super keyDown:event] if we handled it for paging,
    // to prevent cursor movement.
}

// This can be useful if the view is not automatically made first responder
// - (BOOL)acceptsFirstResponder {
// return YES;
// }

@end
