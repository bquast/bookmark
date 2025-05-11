#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @interface MarkdownParser
 * @brief A simple parser to convert basic Markdown text into an NSAttributedString.
 *
 * This parser handles a limited subset of Markdown syntax:
 * - H1 (# Heading)
 * - H2 (## Heading)
 * - Italics (_text_ or *text*)
 * - Special numeric emphasis (*1* rendered as bold italic)
 * - Horizontal rules (---, -------, etc.)
 * - Paragraphs with basic spacing.
 */
@interface MarkdownParser : NSObject

/**
 * @brief Converts a Markdown string to an NSAttributedString with basic styling.
 *
 * @param markdownString The raw Markdown string to be parsed.
 * @param defaultFont The default font to be used for regular text and as a base for styling
 * other elements (e.g., headings will be scaled relative to this font).
 * @return An NSAttributedString with the applied Markdown styling.
 */
+ (NSAttributedString *)attributedStringFromMarkdownString:(NSString *)markdownString
                                                defaultFont:(NSFont *)defaultFont;

@end

NS_ASSUME_NONNULL_END
