#ifndef debug
#define debug(...)
#endif
#define JSTPrefs [NSUserDefaults standardUserDefaults]
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic ignored "-Werror"
#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wunused-function"
#ifndef __clang_analyzer__
//
//  TDParseKit.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDToken;
@class TDTokenizerState;
@class TDNumberState;
@class TDQuoteState;
@class TDSlashState;
@class TDCommentState;
@class TDSymbolState;
@class TDWhitespaceState;
@class TDWordState;
@class TDReader;

/*!
    @class      TDTokenizer
    @brief      A tokenizer divides a string into tokens.
    @details    <p>This class is highly customizable with regard to exactly how this division occurs, but it also has defaults that are suitable for many languages. This class assumes that the character values read from the string lie in the range <tt>0-MAXINT</tt>. For example, the Unicode value of a capital A is 65, so <tt>NSLog(@"%C", (unichar)65);</tt> prints out a capital A.</p>
                <p>The behavior of a tokenizer depends on its character state table. This table is an array of 256 <tt>TDTokenizerState</tt> states. The state table decides which state to enter upon reading a character from the input string.</p>
                <p>For example, by default, upon reading an 'A', a tokenizer will enter a "word" state. This means the tokenizer will ask a <tt>TDWordState</tt> object to consume the 'A', along with the characters after the 'A' that form a word. The state's responsibility is to consume characters and return a complete token.</p>
                <p>The default table sets a <tt>TDSymbolState</tt> for every character from 0 to 255, and then overrides this with:</p>
@code
     From     To    State
        0    ' '    whitespaceState
      'a'    'z'    wordState
      'A'    'Z'    wordState
      160    255    wordState
      '0'    '9'    numberState
      '-'    '-'    numberState
      '.'    '.'    numberState
      '"'    '"'    quoteState
     '\''   '\''    quoteState
      '/'    '/'    commentState
@endcode
                <p>In addition to allowing modification of the state table, this class makes each of the states above available. Some of these states are customizable. For example, wordState allows customization of what characters can be part of a word, after the first character.</p>
*/
@interface TDTokenizer : NSObject {
    NSString *string;
    TDReader *reader;
    
    NSMutableArray *tokenizerStates;
    
    TDNumberState *numberState;
    TDQuoteState *quoteState;
    TDCommentState *commentState;
    TDSymbolState *symbolState;
    TDWhitespaceState *whitespaceState;
    TDWordState *wordState;
}

/*!
    @brief      Convenience factory method. Sets string to read from to <tt>nil</tt>.
    @result     An initialized tokenizer.
*/
+ (id)tokenizer;

/*!
    @brief      Convenience factory method.
    @param      s string to read from.
    @result     An autoreleased initialized tokenizer.
*/
+ (id)tokenizerWithString:(NSString *)s;

/*!
    @brief      Designated Initializer. Constructs a tokenizer to read from the supplied string.
    @param      s string to read from.
    @result     An initialized tokenizer.
*/
- (id)initWithString:(NSString *)s;

/*!
    @brief      Returns the next token.
    @result     the next token.
*/
- (TDToken *)nextToken;

/*!
    @brief      Change the state the tokenizer will enter upon reading any character between "start" and "end".
    @param      state the state for this character range
    @param      start the "start" character. e.g. <tt>'a'</tt> or <tt>65</tt>.
    @param      end the "end" character. <tt>'z'</tt> or <tt>90</tt>.
*/
- (void)setTokenizerState:(TDTokenizerState *)state from:(NSInteger)start to:(NSInteger)end;

/*!
    @property   string
    @brief      The string to read from.
*/
@property (nonatomic, retain) NSString *string;

/*!
    @property    numberState
    @brief       The state this tokenizer uses to build numbers.
*/
@property (nonatomic, retain) TDNumberState *numberState;

/*!
    @property   quoteState
    @brief      The state this tokenizer uses to build quoted strings.
*/
@property (nonatomic, retain) TDQuoteState *quoteState;

/*!
    @property   commentState
    @brief      The state this tokenizer uses to recognize (and possibly ignore) comments.
*/
@property (nonatomic, retain) TDCommentState *commentState;

/*!
    @property   symbolState
    @brief      The state this tokenizer uses to recognize symbols.
*/
@property (nonatomic, retain) TDSymbolState *symbolState;

/*!
    @property   whitespaceState
    @brief      The state this tokenizer uses to recognize (and possibly ignore) whitespace.
*/
@property (nonatomic, retain) TDWhitespaceState *whitespaceState;

/*!
    @property   wordState
    @brief      The state this tokenizer uses to build words.
*/
@property (nonatomic, retain) TDWordState *wordState;
@end

//
//  TDReader.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/21/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
    @class      TDReader 
    @brief      A character-stream reader that allows characters to be pushed back into the stream.
*/
@interface TDReader : NSObject {
    NSString *string;
    NSUInteger cursor;
    NSUInteger length;
}

/*!
    @brief      Designated Initializer. Initializes a reader with a given string.
    @details    Designated Initializer.
    @param      s string from which to read
    @result     an initialized reader
*/
- (id)initWithString:(NSString *)s;

/*!
    @brief      Read a single character
    @result     The character read, or -1 if the end of the stream has been reached
*/
- (NSInteger)read;

/*!
    @brief      Push back a single character
    @details    moves the cursor back one position
*/
- (void)unread;

/*!
    @property   string
    @brief      This reader's string.
*/
@property (nonatomic, retain) NSString *string;
@end

//
//  TDParseKitState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TD_USE_MUTABLE_STRING_BUF 1

@class TDToken;
@class TDTokenizer;
@class TDReader;

/*!
    @class      TDTokenizerState 
    @brief      A <tt>TDTokenizerState</tt> returns a token, given a reader, an initial character read from the reader, and a tokenizer that is conducting an overall tokenization of the reader.
    @details    The tokenizer will typically have a character state table that decides which state to use, depending on an initial character. If a single character is insufficient, a state such as <tt>TDSlashState</tt> will read a second character, and may delegate to another state, such as <tt>TDSlashStarState</tt>. This prospect of delegation is the reason that the <tt>-nextToken</tt> method has a tokenizer argument.
*/
@interface TDTokenizerState : NSObject {
#if TD_USE_MUTABLE_STRING_BUF
    NSMutableString *stringbuf;
#else
    unichar *__strong charbuf;
    NSUInteger length;
    NSUInteger index;
#endif
}

/*!
    @brief      Return a token that represents a logical piece of a reader.
    @param      r the reader from which to read additional characters
    @param      cin the character that a tokenizer used to determine to use this state
    @param      t the tokenizer currently powering the tokenization
    @result     a token that represents a logical piece of the reader
*/
- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t;
@end

//
//  TDQuoteState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
    @class      TDQuoteState 
    @brief      A quote state returns a quoted string token from a reader
    @details    This state will collect characters until it sees a match to the character that the tokenizer used to switch to this state. For example, if a tokenizer uses a double- quote character to enter this state, then <tt>-nextToken</tt> will search for another double-quote until it finds one or finds the end of the reader.
*/
@interface TDQuoteState : TDTokenizerState {
    BOOL balancesEOFTerminatedQuotes;
}

/*!
    @property   balancesEOFTerminatedQuotes
    @brief      if true, this state will append a matching quote char (<tt>'</tt> or <tt>"</tt>) to quotes terminated by EOF. Default is NO.
*/
@property (nonatomic) BOOL balancesEOFTerminatedQuotes;
@end

//
//  TDMultiLineCommentState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 12/28/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDMultiLineCommentState : TDTokenizerState {
    NSMutableArray *startSymbols;
    NSMutableArray *endSymbols;
    NSString *currentStartSymbol;
}

- (void)addStartSymbol:(NSString *)start endSymbol:(NSString *)end;
- (void)removeStartSymbol:(NSString *)start;
@property (nonatomic, retain) NSMutableArray *startSymbols;
@property (nonatomic, retain) NSMutableArray *endSymbols;
@property (nonatomic, copy) NSString *currentStartSymbol;
@end

//
//  TDCommentState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 12/28/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDSymbolRootNode;
@class TDSingleLineCommentState;
@class TDMultiLineCommentState;

/*!
    @class      TDCommentState
    @brief      This state will either delegate to a comment-handling state, or return a <tt>TDSymbol</tt> token with just the first char in it.
    @details    By default, C and C++ style comments. (<tt>//</tt> to end of line and <tt> &0x002A;/</tt>)
*/
@interface TDCommentState : TDTokenizerState {
    TDSymbolRootNode *rootNode;
    TDSingleLineCommentState *singleLineState;
    TDMultiLineCommentState *multiLineState;
    BOOL reportsCommentTokens;
    BOOL balancesEOFTerminatedComments;
}

/*!
    @brief      Adds the given string as a single-line comment start marker. may be multi-char.
    @details    single line comments begin with <tt>start</tt> and continue until the next new line character. e.g. C-style comments (<tt>// comment text</tt>)
    @param      start a single- or multi-character symbol that should be recognized as the start of a single-line comment
*/
- (void)addSingleLineStartSymbol:(NSString *)start;

/*!
    @brief      Removes the given string as a single-line comment start marker. may be multi-char.
    @details    If <tt>start</tt> was never added as a single-line comment start symbol, this has no effect.
    @param      start a single- or multi-character symbol that should no longer be recognized as the start of a single-line comment
*/
- (void)removeSingleLineStartSymbol:(NSString *)start;

/*!
    @brief      Adds the given strings as a multi-line comment start and end markers. both may be multi-char
    @details    <tt>start</tt> and <tt>end</tt> may be different strings. e.g. <tt></tt> and <tt>&0x002A;/</tt>. Also, the actual comment may or may not be multi-line.
    @param      start a single- or multi-character symbol that should be recognized as the start of a multi-line comment
    @param      end a single- or multi-character symbol that should be recognized as the end of a multi-line comment that began with <tt>start</tt>
*/
- (void)addMultiLineStartSymbol:(NSString *)start endSymbol:(NSString *)end;

/*!
    @brief      Removes <tt>start</tt> and its orignall <tt>end</tt> counterpart as a multi-line comment start and end markers.
    @details    If <tt>start</tt> was never added as a multi-line comment start symbol, this has no effect.
    @param      start a single- or multi-character symbol that should no longer be recognized as the start of a multi-line comment
*/
- (void)removeMultiLineStartSymbol:(NSString *)start;

/*!
    @property   reportsCommentTokens
    @brief      if true, the tokenizer associated with this state will report comment tokens, otherwise it silently consumes comments
    @details    if true, this state will return <tt>TDToken</tt>s of type <tt>TDTokenTypeComment</tt>.
                Otherwise, it will silently consume comment text and return the next token from another of the tokenizer's states
*/
@property (nonatomic) BOOL reportsCommentTokens;

/*!
    @property   balancesEOFTerminatedComments
    @brief      if true, this state will append a matching comment string (<tt>&0x002A;/</tt> [C++] or <tt>:)</tt> [XQuery]) to quotes terminated by EOF. Default is NO.
*/
@property (nonatomic) BOOL balancesEOFTerminatedComments;
@property (nonatomic, retain) TDSymbolRootNode *rootNode;
@property (nonatomic, retain) TDSingleLineCommentState *singleLineState;
@property (nonatomic, retain) TDMultiLineCommentState *multiLineState;
@end

//
//  TDSymbolState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDSymbolRootNode;

/*!
    @class      TDSymbolState 
    @brief      The idea of a symbol is a character that stands on its own, such as an ampersand or a parenthesis.
    @details    <p>The idea of a symbol is a character that stands on its own, such as an ampersand or a parenthesis. For example, when tokenizing the expression (isReady)& (isWilling) , a typical tokenizer would return 7 tokens, including one for each parenthesis and one for the ampersand. Thus a series of symbols such as )&( becomes three tokens, while a series of letters such as isReady becomes a single word token.</p>
                <p>Multi-character symbols are an exception to the rule that a symbol is a standalone character. For example, a tokenizer may want less-than-or-equals to tokenize as a single token. This class provides a method for establishing which multi-character symbols an object of this class should treat as single symbols. This allows, for example, "cat <= dog" to tokenize as three tokens, rather than splitting the less-than and equals symbols into separate tokens.</p>
                <p>By default, this state recognizes the following multi- character symbols: <tt>!=</tt>, <tt>:-</tt>, <tt><=</tt>, <tt>>=</tt></p>
*/
@interface TDSymbolState : TDTokenizerState {
    TDSymbolRootNode *rootNode;
    NSMutableArray *addedSymbols;
}

/*!
    @brief      Adds the given string as a multi-character symbol.
    @param      s a multi-character symbol that should be recognized as a single symbol token by this state
*/
- (void)add:(NSString *)s;

/*!
    @brief      Removes the given string as a multi-character symbol.
    @details    If <tt>s</tt> was never added as a multi-character symbol, this has no effect.
    @param      s a multi-character symbol that should no longer be recognized as a single symbol token by this state
*/
- (void)remove:(NSString *)s;
@end

//
//  TDNumberState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
    @class      TDNumberState 
    @brief      A number state returns a number from a reader.
    @details    This state's idea of a number allows an optional, initial minus sign, followed by one or more digits. A decimal point and another string of digits may follow these digits.
*/
@interface TDNumberState : TDTokenizerState {
    BOOL allowsTrailingDot;
    BOOL gotADigit;
    BOOL negative;
    NSInteger c;
    CGFloat floatValue;
}

/*!
    @property   allowsTrailingDot
    @brief      If true, numbers are allowed to end with a trialing dot, e.g. <tt>42.<tt>
    @details    false by default.
*/
@property (nonatomic) BOOL allowsTrailingDot;
@end

//
//  TDWhitespaceState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
    @class      TDWhitespaceState
    @brief      A whitespace state ignores whitespace (such as blanks and tabs), and returns the tokenizer's next token.
    @details    By default, all characters from 0 to 32 are whitespace.
*/
@interface TDWhitespaceState : TDTokenizerState {
    NSMutableArray *whitespaceChars;
    BOOL reportsWhitespaceTokens;
}

/*!
    @brief      Informs whether the given character is recognized as whitespace (and therefore ignored) by this state.
    @param      cin the character to check
    @result     true if the given chracter is recognized as whitespace
*/
- (BOOL)isWhitespaceChar:(NSInteger)cin;

/*!
    @brief      Establish the given character range as whitespace to ignore.
    @param      yn true if the given character range is whitespace
    @param      start the "start" character. e.g. <tt>'a'</tt> or <tt>65</tt>.
    @param      end the "end" character. <tt>'z'</tt> or <tt>90</tt>.
*/
- (void)setWhitespaceChars:(BOOL)yn from:(NSInteger)start to:(NSInteger)end;

/*!
    @property   reportsWhitespaceTokens
    @brief      determines whether a <tt>TDTokenizer</tt> associated with this state reports or silently consumes whitespace tokens. default is <tt>NO</tt> which causes silent consumption of whitespace chars
*/
@property (nonatomic) BOOL reportsWhitespaceTokens;
@end

//
//  TDWordState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
    @class      TDWordState 
    @brief      A word state returns a word from a reader.
    @details    <p>Like other states, a tokenizer transfers the job of reading to this state, depending on an initial character. Thus, the tokenizer decides which characters may begin a word, and this state determines which characters may appear as a second or later character in a word. These are typically different sets of characters; in particular, it is typical for digits to appear as parts of a word, but not as the initial character of a word.</p>
                <p>By default, the following characters may appear in a word. The method setWordChars() allows customizing this.</p>
@code
     From     To
      'a'    'z'
      'A'    'Z'
      '0'    '9'
@endcode
                <p>as well as: minus sign <tt>-</tt>, underscore <tt>_</tt>, and apostrophe <tt>'</tt>.</p>
*/
@interface TDWordState : TDTokenizerState {
    NSMutableArray *wordChars;
}

/*!
    @brief      Establish characters in the given range as valid characters for part of a word after the first character. Note that the tokenizer must determine which characters are valid as the beginning character of a word.
    @param      yn true if characters in the given range are word characters
    @param      start the "start" character. e.g. <tt>'a'</tt> or <tt>65</tt>.
    @param      end the "end" character. <tt>'z'</tt> or <tt>90</tt>.
*/
- (void)setWordChars:(BOOL)yn from:(NSInteger)start to:(NSInteger)end;

/*!
    @brief      Informs whether the given character is recognized as a word character by this state.
    @param      cin the character to check
    @result     true if the given chracter is recognized as a word character
*/
- (BOOL)isWordChar:(NSInteger)c;
@end

//
//  TDSingleLineCommentState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 12/28/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDSingleLineCommentState : TDTokenizerState {
    NSMutableArray *startSymbols;
    NSString *currentStartSymbol;
}

@end

//
//  TDToken.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
    @typedef    enum TDTokenType
    @brief      Indicates the type of a <tt>TDToken</tt>
    @var        TDTokenTypeEOF A constant indicating that the endo fo the stream has been read.
    @var        TDTokenTypeNumber A constant indicating that a token is a number, like <tt>3.14</tt>.
    @var        TDTokenTypeQuotedString A constant indicating that a token is a quoted string, like <tt>"Launch Mi"</tt>.
    @var        TDTokenTypeSymbol A constant indicating that a token is a symbol, like <tt>"&lt;="</tt>.
    @var        TDTokenTypeWord A constant indicating that a token is a word, like <tt>cat</tt>.
*/
typedef enum {
    TDTokenTypeEOF,
    TDTokenTypeNumber,
    TDTokenTypeQuotedString,
    TDTokenTypeSymbol,
    TDTokenTypeWord,
    TDTokenTypeWhitespace,
    TDTokenTypeComment
} TDTokenType;

/*!
    @class      TDToken
    @brief      A token represents a logical chunk of a string.
    @details    For example, a typical tokenizer would break the string <tt>"1.23 &lt;= 12.3"</tt> into three tokens: the number <tt>1.23</tt>, a less-than-or-equal symbol, and the number <tt>12.3</tt>. A token is a receptacle, and relies on a tokenizer to decide precisely how to divide a string into tokens.
*/
@interface TDToken : NSObject {
    CGFloat floatValue;
    NSString *stringValue;
    TDTokenType tokenType;
    
    BOOL number;
    BOOL quotedString;
    BOOL symbol;
    BOOL word;
    BOOL whitespace;
    BOOL comment;
    
    id value;
}

/*!
    @brief      Factory method for creating a singleton <tt>TDToken</tt> used to indicate that there are no more tokens.
    @result     A singleton used to indicate that there are no more tokens.
*/
+ (TDToken *)EOFToken;

/*!
    @brief      Factory convenience method for creating an autoreleased token.
    @param      t the type of this token.
    @param      s the string value of this token.
    @param      n the number falue of this token.
    @result     an autoreleased initialized token.
*/
+ (id)tokenWithTokenType:(TDTokenType)t stringValue:(NSString *)s floatValue:(CGFloat)n;

/*!
    @brief      Designated initializer. Constructs a token of the indicated type and associated string or numeric values.
    @param      t the type of this token.
    @param      s the string value of this token.
    @param      n the number falue of this token.
    @result     an autoreleased initialized token.
*/
- (id)initWithTokenType:(TDTokenType)t stringValue:(NSString *)s floatValue:(CGFloat)n;

/*!
    @brief      Returns true if the supplied object is an equivalent <tt>TDToken</tt>, ignoring differences in case.
    @param      obj the object to compare this token to.
    @result     true if <tt>obj</tt> is an equivalent <tt>TDToken</tt>, ignoring differences in case.
*/
- (BOOL)isEqualIgnoringCase:(id)obj;

/*!
    @brief      Returns more descriptive textual representation than <tt>-description</tt> which may be useful for debugging puposes only.
    @details    Usually of format similar to: <tt>&lt;QuotedString "Launch Mi"></tt>, <tt>&lt;Word cat></tt>, or <tt>&lt;Num 3.14></tt>
    @result     A textual representation including more descriptive information than <tt>-description</tt>.
*/
- (NSString *)debugDescription;

/*!
    @property   number
    @brief      True if this token is a number. getter=isNumber
*/
@property (nonatomic, readonly, getter=isNumber) BOOL number;

/*!
    @property   quotedString
    @brief      True if this token is a quoted string. getter=isQuotedString
*/
@property (nonatomic, readonly, getter=isQuotedString) BOOL quotedString;

/*!
    @property   symbol
    @brief      True if this token is a symbol. getter=isSymbol
*/
@property (nonatomic, readonly, getter=isSymbol) BOOL symbol;

/*!
    @property   word
    @brief      True if this token is a word. getter=isWord
*/
@property (nonatomic, readonly, getter=isWord) BOOL word;

/*!
    @property   whitespace
    @brief      True if this token is whitespace. getter=isWhitespace
*/
@property (nonatomic, readonly, getter=isWhitespace) BOOL whitespace;

/*!
    @property   comment
    @brief      True if this token is a comment. getter=isComment
*/
@property (nonatomic, readonly, getter=isComment) BOOL comment;

/*!
    @property   tokenType
    @brief      The type of this token.
*/
@property (nonatomic, readonly) TDTokenType tokenType;

/*!
    @property   floatValue
    @brief      The numeric value of this token.
*/
@property (nonatomic, readonly) CGFloat floatValue;

/*!
    @property   stringValue
    @brief      The string value of this token.
*/
@property (nonatomic, readonly, copy) NSString *stringValue;

/*!
    @property   value
    @brief      Returns an object that represents the value of this token.
*/
@property (nonatomic, readonly, copy) id value;
@end

//
//  TDSymbolNode.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
    @class      TDSymbolNode 
    @brief      A <tt>TDSymbolNode</tt> object is a member of a tree that contains all possible prefixes of allowable symbols.
    @details    A <tt>TDSymbolNode</tt> object is a member of a tree that contains all possible prefixes of allowable symbols. Multi-character symbols appear in a <tt>TDSymbolNode</tt> tree with one node for each character. For example, the symbol <tt>=:~</tt> will appear in a tree as three nodes. The first node contains an equals sign, and has a child; that child contains a colon and has a child; this third child contains a tilde, and has no children of its own. If the colon node had another child for a dollar sign character, then the tree would contain the symbol <tt>=:$</tt>. A tree of <tt>TDSymbolNode</tt> objects collaborate to read a (potentially multi-character) symbol from an input stream. A root node with no character of its own finds an initial node that represents the first character in the input. This node looks to see if the next character in the stream matches one of its children. If so, the node delegates its reading task to its child. This approach walks down the tree, pulling symbols from the input that match the path down the tree. When a node does not have a child that matches the next character, we will have read the longest possible symbol prefix. This prefix may or may not be a valid symbol. Consider a tree that has had <tt>=:~</tt> added and has not had <tt>=:</tt> added. In this tree, of the three nodes that contain =:~, only the first and third contain complete symbols. If, say, the input contains <tt>=:a</tt>, the colon node will not have a child that matches the <tt>'a'</tt> and so it will stop reading. The colon node has to "unread": it must push back its character, and ask its parent to unread. Unreading continues until it reaches an ancestor that represents a valid symbol.
*/
@interface TDSymbolNode : NSObject {
    NSString *ancestry;
    TDSymbolNode *parent;
    NSMutableDictionary *children;
    NSInteger character;
    NSString *string;
}

/*!
    @brief      Initializes a <tt>TDSymbolNode</tt> with the given parent, representing the given character.
    @param      p the parent of this node
    @param      c the character for this node
    @result     An initialized <tt>TDSymbolNode</tt>
*/
- (id)initWithParent:(TDSymbolNode *)p character:(NSInteger)c;

/*!
    @property   ancestry
    @brief      The string of the mulit-character symbol this node represents.
*/
@property (nonatomic, readonly, retain) NSString *ancestry;
@end

//
//  TDSymbolRootNode.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDReader;

/*!
    @class      TDSymbolRootNode 
    @brief      This class is a special case of a <tt>TDSymbolNode</tt>.
    @details    This class is a special case of a <tt>TDSymbolNode</tt>. A <tt>TDSymbolRootNode</tt> object has no symbol of its own, but has children that represent all possible symbols.
*/
@interface TDSymbolRootNode : TDSymbolNode {
}

/*!
    @brief      Adds the given string as a multi-character symbol.
    @param      s a multi-character symbol that should be recognized as a single symbol token by this state
*/
- (void)add:(NSString *)s;

/*!
    @brief      Removes the given string as a multi-character symbol.
    @param      s a multi-character symbol that should no longer be recognized as a single symbol token by this state
    @details    if <tt>s</tt> was never added as a multi-character symbol, this has no effect
*/
- (void)remove:(NSString *)s;

/*!
    @brief      Return a symbol string from a reader.
    @param      r the reader from which to read
    @param      cin the character from witch to start
    @result     a symbol string from a reader
*/
- (NSString *)nextSymbol:(TDReader *)r startingWith:(NSInteger)cin;
@end

//
//  TDParseKit.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//


@interface TDTokenizer ()
- (void)addTokenizerState:(TDTokenizerState *)state from:(NSInteger)start to:(NSInteger)end;
- (TDTokenizerState *)tokenizerStateFor:(NSInteger)c;
@property (nonatomic, retain) TDReader *reader;
@property (nonatomic, retain) NSMutableArray *tokenizerStates;
@end

@implementation TDTokenizer

+ (id)tokenizer {
    return [self tokenizerWithString:nil];
}


+ (id)tokenizerWithString:(NSString *)s {
    return [[[self alloc] initWithString:s] autorelease];
}


- (id)init {
    return [self initWithString:nil];
}


- (id)initWithString:(NSString *)s {
    self = [super init];
    if (self) {
        self.string = s;
        self.reader = [[[TDReader alloc] init] autorelease];
        
        numberState = [[TDNumberState alloc] init];
        quoteState = [[TDQuoteState alloc] init];
        commentState = [[TDCommentState alloc] init];
        symbolState = [[TDSymbolState alloc] init];
        whitespaceState = [[TDWhitespaceState alloc] init];
        wordState = [[TDWordState alloc] init];
        
        [symbolState add:@"<="];
        [symbolState add:@">="];
        [symbolState add:@"!="];
        [symbolState add:@"=="];
        
        [commentState addSingleLineStartSymbol:@"//"];
        [commentState addMultiLineStartSymbol:@"/*" endSymbol:@"*/"];
        
        tokenizerStates = [[NSMutableArray alloc] initWithCapacity:256];
        
        [self addTokenizerState:whitespaceState from:   0 to: ' ']; // From:  0 to: 32    From:0x00 to:0x20
        [self addTokenizerState:symbolState     from:  33 to:  33];
        [self addTokenizerState:quoteState      from: '"' to: '"']; // From: 34 to: 34    From:0x22 to:0x22
        [self addTokenizerState:symbolState     from:  35 to:  38];
        [self addTokenizerState:quoteState      from:'\'' to:'\'']; // From: 39 to: 39    From:0x27 to:0x27
        [self addTokenizerState:symbolState     from:  40 to:  42];
        [self addTokenizerState:symbolState     from: '+' to: '+']; // From: 43 to: 43    From:0x2B to:0x2B
        [self addTokenizerState:symbolState     from:  44 to:  44];
        [self addTokenizerState:numberState     from: '-' to: '-']; // From: 45 to: 45    From:0x2D to:0x2D
        [self addTokenizerState:numberState     from: '.' to: '.']; // From: 46 to: 46    From:0x2E to:0x2E
        [self addTokenizerState:commentState    from: '/' to: '/']; // From: 47 to: 47    From:0x2F to:0x2F
        [self addTokenizerState:numberState     from: '0' to: '9']; // From: 48 to: 57    From:0x30 to:0x39
        [self addTokenizerState:symbolState     from:  58 to:  64];
        [self addTokenizerState:wordState       from: 'A' to: 'Z']; // From: 65 to: 90    From:0x41 to:0x5A
        [self addTokenizerState:symbolState     from:  91 to:  96];
        [self addTokenizerState:wordState       from: 'a' to: 'z']; // From: 97 to:122    From:0x61 to:0x7A
        [self addTokenizerState:symbolState     from: 123 to: 191];
        [self addTokenizerState:wordState       from:0xC0 to:0xFF]; // From:192 to:255    From:0xC0 to:0xFF
    }
    return self;
}


- (void)dealloc {
    self.string = nil;
    self.reader = nil;
    self.tokenizerStates = nil;
    self.numberState = nil;
    self.quoteState = nil;
    self.commentState = nil;
    self.symbolState = nil;
    self.whitespaceState = nil;
    self.wordState = nil;
    [super dealloc];
}


- (TDToken *)nextToken {
    NSInteger c = [reader read];
    
    TDToken *result = nil;
    
    if (-1 == c) {
        result = [TDToken EOFToken];
    } else {
        TDTokenizerState *state = [self tokenizerStateFor:c];
        if (state) {
            result = [state nextTokenFromReader:reader startingWith:c tokenizer:self];
        } else {
            result = [TDToken EOFToken];
        }
    }
    
    return result;
}


- (void)addTokenizerState:(TDTokenizerState *)state from:(NSInteger)start to:(NSInteger)end {
    NSParameterAssert(state);
    
    //void (*addObject)(id, SEL, id);
    //addObject = (void (*)(id, SEL, id))[tokenizerStates methodForSelector:@selector(addObject:)];
    
    NSInteger i = start;
    for ( ; i <= end; i++) {
        [tokenizerStates addObject:state];
        //addObject(tokenizerStates, @selector(addObject:), state);
    }
}


- (void)setTokenizerState:(TDTokenizerState *)state from:(NSInteger)start to:(NSInteger)end {
    NSParameterAssert(state);

    //void (*relaceObject)(id, SEL, NSUInteger, id);
    //relaceObject = (void (*)(id, SEL, NSUInteger, id))[tokenizerStates methodForSelector:@selector(replaceObjectAtIndex:withObject:)];

    NSInteger i = start;
    for ( ; i <= end; i++) {
        [tokenizerStates replaceObjectAtIndex:i withObject:state];
        //relaceObject(tokenizerStates, @selector(replaceObjectAtIndex:withObject:), i, state);
    }
}


- (TDReader *)reader {
    return reader;
}


- (void)setReader:(TDReader *)r {
    if (reader != r) {
        [reader release];
        reader = [r retain];
        reader.string = string;
    }
}


- (NSString *)string {
    return string;
}


- (void)setString:(NSString *)s {
    if (string != s) {
        [string retain];
        string = [s retain];
    }
    reader.string = string;
}


#pragma mark -

- (TDTokenizerState *)tokenizerStateFor:(NSInteger)c {
    if (c < 0 || c > 255) {
        if (c >= 0x19E0 && c <= 0x19FF) { // khmer symbols
            return symbolState;
        } else if (c >= 0x2000 && c <= 0x2BFF) { // various symbols
            return symbolState;
        } else if (c >= 0x2E00 && c <= 0x2E7F) { // supplemental punctuation
            return symbolState;
        } else if (c >= 0x3000 && c <= 0x303F) { // cjk symbols & punctuation
            return symbolState;
        } else if (c >= 0x3200 && c <= 0x33FF) { // enclosed cjk letters and months, cjk compatibility
            return symbolState;
        } else if (c >= 0x4DC0 && c <= 0x4DFF) { // yijing hexagram symbols
            return symbolState;
        } else if (c >= 0xFE30 && c <= 0xFE6F) { // cjk compatibility forms, small form variants
            return symbolState;
        } else if (c >= 0xFF00 && c <= 0xFFFF) { // hiragana & katakana halfwitdh & fullwidth forms, Specials
            return symbolState;
        } else {
            return wordState;
        }
    }
    return [tokenizerStates objectAtIndex:c];
}

@synthesize numberState;
@synthesize quoteState;
@synthesize commentState;
@synthesize symbolState;
@synthesize whitespaceState;
@synthesize wordState;
@synthesize string;
@synthesize tokenizerStates;
@end

//
//  TDReader.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/21/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//


@implementation TDReader

- (id)init {
    return [self initWithString:nil];
}


- (id)initWithString:(NSString *)s {
    self = [super init];
    if (self) {
        self.string = s;
    }
    return self;
}


- (void)dealloc {
    self.string = nil;
    [super dealloc];
}


- (NSString *)string {
    return string;
}


- (void)setString:(NSString *)s {
    if (string != s) {
        [string release];
        string = [s retain];
        length = string.length;
    }
    // reset cursor
    cursor = 0;
}


- (NSInteger)read {
    if (0 == length || cursor > length - 1) {
        return -1;
    }
    return [string characterAtIndex:cursor++];
}


- (void)unread {
    cursor = (0 == cursor) ? 0 : cursor - 1;
}

@end

//
//  TDParseKitState.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//


@interface TDTokenizerState ()
- (void)reset;
- (void)append:(NSInteger)c;
- (void)appendString:(NSString *)s;
- (NSString *)bufferedString;

#if TD_USE_MUTABLE_STRING_BUF
@property (nonatomic, retain) NSMutableString *stringbuf;
#else
- (void)checkBufLength;
- (unichar *)mallocCharbuf:(NSUInteger)size;
#endif
@end

@implementation TDTokenizerState

- (void)dealloc {
#if TD_USE_MUTABLE_STRING_BUF
    self.stringbuf = nil;
#else
    if (charbuf && ![[NSGarbageCollector defaultCollector] isEnabled]) {
        free(charbuf);
        charbuf = NULL;
    }
#endif
    [super dealloc];
}


- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t {
    NSAssert(0, @"TDTokenizerState is an Abstract Classs. nextTokenFromStream:at:tokenizer: must be overriden");
    return nil;
}


- (void)reset {
#if TD_USE_MUTABLE_STRING_BUF
    self.stringbuf = [NSMutableString string];
#else
    if (charbuf && ![[NSGarbageCollector defaultCollector] isEnabled]) {
        free(charbuf);
        charbuf = NULL;
    }
    index = 0;
    length = 16;
    charbuf = [self mallocCharbuf:length];
#endif
}


- (void)append:(NSInteger)c {
#if TD_USE_MUTABLE_STRING_BUF
    [stringbuf appendFormat:@"%C", (unsigned short)c];
#else 
    [self checkBufLength];
    charbuf[index++] = c;
#endif
}


- (void)appendString:(NSString *)s {
#if TD_USE_MUTABLE_STRING_BUF
    [stringbuf appendString:s];
#else 
    // TODO
    NSAssert1(0, @"-[TDTokenizerState %s] not impl for charbuf", _cmd);
#endif
}


- (NSString *)bufferedString {
#if TD_USE_MUTABLE_STRING_BUF
    return [[stringbuf copy] autorelease];
#else
    return [[[NSString alloc] initWithCharacters:(const unichar *)charbuf length:index] autorelease];
//    return [[[NSString alloc] initWithBytes:charbuf length:index encoding:NSUTF8StringEncoding] autorelease];
#endif
}


#if TD_USE_MUTABLE_STRING_BUF
#else
- (void)checkBufLength {
    if (index >= length) {
        unichar *nb = [self mallocCharbuf:length * 2];
        
        NSInteger j = 0;
        for ( ; j < length; j++) {
            nb[j] = charbuf[j];
        }
        if (![[NSGarbageCollector defaultCollector] isEnabled]) {
            free(charbuf);
            charbuf = NULL;
        }
        charbuf = nb;
        
        length = length * 2;
    }
}


- (unichar *)mallocCharbuf:(NSUInteger)size {
    unichar *result = NULL;
    if ((result = (unichar *)NSAllocateCollectable(size, 0)) == NULL) {
        [NSException raise:@"Out of memory" format:nil];
    }
    return result;
}
#endif

#if TD_USE_MUTABLE_STRING_BUF
@synthesize stringbuf;
#endif
@end

//
//  TDQuoteState.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//




@implementation TDQuoteState

- (void)dealloc {
    [super dealloc];
}


- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t {
    NSParameterAssert(r);
    [self reset];
    
    [self append:cin];
    NSInteger c;
    do {
        c = [r read];
        if (-1 == c) {
            c = cin;
            if (balancesEOFTerminatedQuotes) {
                [self append:c];
            }
        } else {
            [self append:c];
        }
        
    } while (c != cin);
    
    return [TDToken tokenWithTokenType:TDTokenTypeQuotedString stringValue:[self bufferedString] floatValue:0.0];
}

@synthesize balancesEOFTerminatedQuotes;
@end

//
//  TDMultiLineCommentState.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 12/28/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//








@implementation TDMultiLineCommentState

- (id)init {
    self = [super init];
    if (self) {
        self.startSymbols = [NSMutableArray array];
        self.endSymbols = [NSMutableArray array];
    }
    return self;
}


- (void)dealloc {
    self.startSymbols = nil;
    self.endSymbols = nil;
    self.currentStartSymbol = nil;
    [super dealloc];
}


- (void)addStartSymbol:(NSString *)start endSymbol:(NSString *)end {
    NSParameterAssert(start.length);
    NSParameterAssert(end.length);
    [startSymbols addObject:start];
    [endSymbols addObject:end];
}


- (void)removeStartSymbol:(NSString *)start {
    NSParameterAssert(start.length);
    NSInteger i = [startSymbols indexOfObject:start];
    if (NSNotFound != i) {
        [startSymbols removeObject:start];
        [endSymbols removeObjectAtIndex:i]; // this should always be in range.
    }
}


- (void)unreadSymbol:(NSString *)s fromReader:(TDReader *)r {
    NSInteger len = s.length;
    NSInteger i = 0;
    for ( ; i < len - 1; i++) {
        [r unread];
    }
}


- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t {
    NSParameterAssert(r);
    NSParameterAssert(t);
    
    BOOL balanceEOF = t.commentState.balancesEOFTerminatedComments;
    BOOL reportTokens = t.commentState.reportsCommentTokens;
    if (reportTokens) {
        [self reset];
        [self appendString:currentStartSymbol];
    }
    
    NSInteger i = [startSymbols indexOfObject:currentStartSymbol];
    NSString *currentEndSymbol = [endSymbols objectAtIndex:i];
    NSInteger e = [currentEndSymbol characterAtIndex:0];
    
    // get the definitions of all multi-char comment start and end symbols from the commentState
    TDSymbolRootNode *rootNode = t.commentState.rootNode;
        
    NSInteger c;
    while (1) {
        c = [r read];
        if (-1 == c) {
            if (balanceEOF) {
                [self appendString:currentEndSymbol];
            }
            break;
        }
        
        if (e == c) {
            NSString *peek = [rootNode nextSymbol:r startingWith:e];
            if ([currentEndSymbol isEqualToString:peek]) {
                if (reportTokens) {
                    [self appendString:currentEndSymbol];
                }
                c = [r read];
                break;
            } else {
                [self unreadSymbol:peek fromReader:r];
                if (e != [peek characterAtIndex:0]) {
                    if (reportTokens) {
                        [self append:c];
                    }
                    c = [r read];
                }
            }
        }
        if (reportTokens) {
            [self append:c];
        }
    }
    
    if (-1 != c) {
        [r unread];
    }
    
    self.currentStartSymbol = nil;

    if (reportTokens) {
        return [TDToken tokenWithTokenType:TDTokenTypeComment stringValue:[self bufferedString] floatValue:0.0];
    } else {
        return [t nextToken];
    }
}

@synthesize startSymbols;
@synthesize endSymbols;
@synthesize currentStartSymbol;
@end

//
//  TDCommentState.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 12/28/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//




@interface TDSingleLineCommentState ()
- (void)addStartSymbol:(NSString *)start;
- (void)removeStartSymbol:(NSString *)start;
@property (nonatomic, retain) NSMutableArray *startSymbols;
@property (nonatomic, retain) NSString *currentStartSymbol;
@end



@implementation TDCommentState

- (id)init {
    self = [super init];
    if (self) {
        self.rootNode = [[[TDSymbolRootNode alloc] init] autorelease];
        self.singleLineState = [[[TDSingleLineCommentState alloc] init] autorelease];
        self.multiLineState = [[[TDMultiLineCommentState alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
    self.rootNode = nil;
    self.singleLineState = nil;
    self.multiLineState = nil;
    [super dealloc];
}


- (void)addSingleLineStartSymbol:(NSString *)start {
    NSParameterAssert(start.length);
    [rootNode add:start];
    [singleLineState addStartSymbol:start];
}


- (void)removeSingleLineStartSymbol:(NSString *)start {
    NSParameterAssert(start.length);
    [rootNode remove:start];
    [singleLineState removeStartSymbol:start];
}


- (void)addMultiLineStartSymbol:(NSString *)start endSymbol:(NSString *)end {
    NSParameterAssert(start.length);
    NSParameterAssert(end.length);
    [rootNode add:start];
    [rootNode add:end];
    [multiLineState addStartSymbol:start endSymbol:end];
}


- (void)removeMultiLineStartSymbol:(NSString *)start {
    NSParameterAssert(start.length);
    [rootNode remove:start];
    [multiLineState removeStartSymbol:start];
}


- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t {
    NSParameterAssert(r);
    NSParameterAssert(t);

    NSString *symbol = [rootNode nextSymbol:r startingWith:cin];

    if ([multiLineState.startSymbols containsObject:symbol]) {
        multiLineState.currentStartSymbol = symbol;
        return [multiLineState nextTokenFromReader:r startingWith:cin tokenizer:t];
    } else if ([singleLineState.startSymbols containsObject:symbol]) {
        singleLineState.currentStartSymbol = symbol;
        return [singleLineState nextTokenFromReader:r startingWith:cin tokenizer:t];
    } else {
        NSInteger i = 0;
        for ( ; i < symbol.length - 1; i++) {
            [r unread];
        }
        return [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:[NSString stringWithFormat:@"%C", (unsigned short)cin] floatValue:0.0];
    }
}

@synthesize rootNode;
@synthesize singleLineState;
@synthesize multiLineState;
@synthesize reportsCommentTokens;
@synthesize balancesEOFTerminatedComments;
@end

//
//  TDSymbolState.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//


@interface TDSymbolState ()
@property (nonatomic, retain) TDSymbolRootNode *rootNode;
@property (nonatomic, retain) NSMutableArray *addedSymbols;
@end

@implementation TDSymbolState

- (id)init {
    self = [super init];
    if (self) {
        self.rootNode = [[[TDSymbolRootNode alloc] init] autorelease];
        self.addedSymbols = [NSMutableArray array];
    }
    return self;
}


- (void)dealloc {
    self.rootNode = nil;
    self.addedSymbols = nil;
    [super dealloc];
}


- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t {
    NSParameterAssert(r);
    NSString *symbol = [rootNode nextSymbol:r startingWith:cin];
    NSInteger len = symbol.length;

    if (0 == len || (len > 1 && [addedSymbols containsObject:symbol])) {
        return [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:symbol floatValue:0.0];
    } else {
        NSInteger i = 0;
        for ( ; i < len - 1; i++) {
            [r unread];
        }
        return [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:[NSString stringWithFormat:@"%C", (unsigned short)cin] floatValue:0.0];
    }
}


- (void)add:(NSString *)s {
    NSParameterAssert(s);
    [rootNode add:s];
    [addedSymbols addObject:s];
}


- (void)remove:(NSString *)s {
    NSParameterAssert(s);
    [rootNode remove:s];
    [addedSymbols removeObject:s];
}

@synthesize rootNode;
@synthesize addedSymbols;
@end

//
//  TDNumberState.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//




@interface TDNumberState ()
- (CGFloat)absorbDigitsFromReader:(TDReader *)r isFraction:(BOOL)fraction;
- (CGFloat)value;
- (void)parseLeftSideFromReader:(TDReader *)r;
- (void)parseRightSideFromReader:(TDReader *)r;
- (void)reset:(NSInteger)cin;
@end

@implementation TDNumberState

- (void)dealloc {
    [super dealloc];
}


- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t {
    NSParameterAssert(r);
    NSParameterAssert(t);

    [self reset];
    negative = NO;
    NSInteger originalCin = cin;
    
    if ('-' == cin) {
        negative = YES;
        cin = [r read];
        [self append:'-'];
    } else if ('+' == cin) {
        cin = [r read];
        [self append:'+'];
    }
    
    [self reset:cin];
    if ('.' == c) {
        [self parseRightSideFromReader:r];
    } else {
        [self parseLeftSideFromReader:r];
        [self parseRightSideFromReader:r];
    }
    
    // erroneous ., +, or -
    if (!gotADigit) {
        if (negative && -1 != c) { // ??
            [r unread];
        }
        return [t.symbolState nextTokenFromReader:r startingWith:originalCin tokenizer:t];
    }
    
    if (-1 != c) {
        [r unread];
    }

    if (negative) {
        floatValue = -floatValue;
    }
    
    return [TDToken tokenWithTokenType:TDTokenTypeNumber stringValue:[self bufferedString] floatValue:[self value]];
}


- (CGFloat)value {
    return floatValue;
}


- (CGFloat)absorbDigitsFromReader:(TDReader *)r isFraction:(BOOL)isFraction {
    CGFloat divideBy = 1.0;
    CGFloat v = 0.0;
    
    while (1) {
        if (isdigit((int)c)) {
            [self append:c];
            gotADigit = YES;
            v = v * 10.0 + (c - '0');
            c = [r read];
            if (isFraction) {
                divideBy *= 10.0;
            }
        } else {
            break;
        }
    }
    
    if (isFraction) {
        v = v / divideBy;
    }

    return (CGFloat)v;
}


- (void)parseLeftSideFromReader:(TDReader *)r {
    floatValue = [self absorbDigitsFromReader:r isFraction:NO];
}


- (void)parseRightSideFromReader:(TDReader *)r {
    if ('.' == c) {
        NSInteger n = [r read];
        BOOL nextIsDigit = isdigit((int)n);
        if (-1 != n) {
            [r unread];
        }

        if (nextIsDigit || allowsTrailingDot) {
            [self append:'.'];
            if (nextIsDigit) {
                c = [r read];
                floatValue += [self absorbDigitsFromReader:r isFraction:YES];
            }
        }
    }
}


- (void)reset:(NSInteger)cin {
    gotADigit = NO;
    floatValue = 0.0;
    c = cin;
}

@synthesize allowsTrailingDot;
@end

//
//  TDWhitespaceState.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//


#define TDTRUE (id)kCFBooleanTrue
#define TDFALSE (id)kCFBooleanFalse



@interface TDWhitespaceState ()
@property (nonatomic, retain) NSMutableArray *whitespaceChars;
@end

@implementation TDWhitespaceState

- (id)init {
    self = [super init];
    if (self) {
        const NSUInteger len = 255;
        self.whitespaceChars = [NSMutableArray arrayWithCapacity:len];
        NSUInteger i = 0;
        for ( ; i <= len; i++) {
            [whitespaceChars addObject:TDFALSE];
        }
        
        [self setWhitespaceChars:YES from:0 to:' '];
    }
    return self;
}


- (void)dealloc {
    self.whitespaceChars = nil;
    [super dealloc];
}


- (void)setWhitespaceChars:(BOOL)yn from:(NSInteger)start to:(NSInteger)end {
    NSUInteger len = whitespaceChars.count;
    if (start > len || end > len || start < 0 || end < 0) {
        [NSException raise:@"TDWhitespaceStateNotSupportedException" format:@"TDWhitespaceState only supports setting word chars for chars in the latin1 set (under 256)"];
    }

    id obj = yn ? TDTRUE : TDFALSE;
    NSUInteger i = start;
    for ( ; i <= end; i++) {
        [whitespaceChars replaceObjectAtIndex:i withObject:obj];
    }
}


- (BOOL)isWhitespaceChar:(NSInteger)cin {
    if (cin < 0 || cin > whitespaceChars.count - 1) {
        return NO;
    }
    return TDTRUE == [whitespaceChars objectAtIndex:cin];
}


- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t {
    NSParameterAssert(r);
    if (reportsWhitespaceTokens) {
        [self reset];
    }
    
    NSInteger c = cin;
    while ([self isWhitespaceChar:c]) {
        if (reportsWhitespaceTokens) {
            [self append:c];
        }
        c = [r read];
    }
    if (-1 != c) {
        [r unread];
    }
    
    if (reportsWhitespaceTokens) {
        return [TDToken tokenWithTokenType:TDTokenTypeWhitespace stringValue:[self bufferedString] floatValue:0.0];
    } else {
        return [t nextToken];
    }
}

@synthesize whitespaceChars;
@synthesize reportsWhitespaceTokens;
@end


//
//  TDWordState.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//


#define TDTRUE (id)kCFBooleanTrue
#define TDFALSE (id)kCFBooleanFalse



@interface TDWordState () 
- (BOOL)isWordChar:(NSInteger)c;

@property (nonatomic, retain) NSMutableArray *wordChars;
@end

@implementation TDWordState

- (id)init {
    self = [super init];
    if (self) {
        const NSUInteger len = 255;
        self.wordChars = [NSMutableArray arrayWithCapacity:len];
        NSInteger i = 0;
        for ( ; i <= len; i++) {
            [wordChars addObject:TDFALSE];
        }
        
        [self setWordChars:YES from: 'a' to: 'z'];
        [self setWordChars:YES from: 'A' to: 'Z'];
        [self setWordChars:YES from: '0' to: '9'];
        [self setWordChars:YES from: '-' to: '-'];
        [self setWordChars:YES from: '_' to: '_'];
        [self setWordChars:YES from:'\'' to:'\''];
        [self setWordChars:YES from:0xC0 to:0xFF];
    }
    return self;
}


- (void)dealloc {
    self.wordChars = nil;
    [super dealloc];
}


- (void)setWordChars:(BOOL)yn from:(NSInteger)start to:(NSInteger)end {
    NSInteger len = wordChars.count;
    if (start > len || end > len || start < 0 || end < 0) {
        [NSException raise:@"TDWordStateNotSupportedException" format:@"TDWordState only supports setting word chars for chars in the latin1 set (under 256)"];
    }
    
    id obj = yn ? TDTRUE : TDFALSE;
    NSInteger i = start;
    for ( ; i <= end; i++) {
        [wordChars replaceObjectAtIndex:i withObject:obj];
    }
}


- (BOOL)isWordChar:(NSInteger)c {    
    if (c > -1 && c < wordChars.count - 1) {
        return (TDTRUE == [wordChars objectAtIndex:c]);
    }

    if (c >= 0x2000 && c <= 0x2BFF) { // various symbols
        return NO;
    } else if (c >= 0xFE30 && c <= 0xFE6F) { // general punctuation
        return NO;
    } else if (c >= 0xFE30 && c <= 0xFE6F) { // western musical symbols
        return NO;
    } else if (c >= 0xFF00 && c <= 0xFF65) { // symbols within Hiragana & Katakana
        return NO;            
    } else if (c >= 0xFFF0 && c <= 0xFFFF) { // specials
        return NO;            
    } else if (c < 0) {
        return NO;
    } else {
        return YES;
    }
}


- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t {
    NSParameterAssert(r);
    [self reset];
    
    NSInteger c = cin;
    do {
        [self append:c];
        c = [r read];
    } while ([self isWordChar:c]);
    
    if (-1 != c) {
        [r unread];
    }
    
    return [TDToken tokenWithTokenType:TDTokenTypeWord stringValue:[self bufferedString] floatValue:0.0];
}


@synthesize wordChars;
@end

//
//  TDSingleLineCommentState.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 12/28/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//





@implementation TDSingleLineCommentState

- (id)init {
    self = [super init];
    if (self) {
        self.startSymbols = [NSMutableArray array];
    }
    return self;
}


- (void)dealloc {
    self.startSymbols = nil;
    self.currentStartSymbol = nil;
    [super dealloc];
}


- (void)addStartSymbol:(NSString *)start {
    NSParameterAssert(start.length);
    [startSymbols addObject:start];
}


- (void)removeStartSymbol:(NSString *)start {
    NSParameterAssert(start.length);
    [startSymbols removeObject:start];
}


- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t {
    NSParameterAssert(r);
    NSParameterAssert(t);
    
    BOOL reportTokens = t.commentState.reportsCommentTokens;
    if (reportTokens) {
        [self reset];
        if (currentStartSymbol.length > 1) {
            [self appendString:currentStartSymbol];
        }
    }
    
    NSInteger c;
    while (1) {
        c = [r read];
        if ('\n' == c || '\r' == c || -1 == c) {
            break;
        }
        if (reportTokens) {
            [self append:c];
        }
    }
    
    if (-1 != c) {
        [r unread];
    }
    
    self.currentStartSymbol = nil;
    
    if (reportTokens) {
        return [TDToken tokenWithTokenType:TDTokenTypeComment stringValue:[self bufferedString] floatValue:0.0];
    } else {
        return [t nextToken];
    }
}

@synthesize startSymbols;
@synthesize currentStartSymbol;
@end

//
//  TDToken.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//


@interface TDTokenEOF : TDToken {}
+ (TDTokenEOF *)instance;
@end

@implementation TDTokenEOF

static TDTokenEOF *EOFToken = nil;

+ (TDTokenEOF *)instance {
    @synchronized(self) {
        if (!EOFToken) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return EOFToken;
}


+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (!EOFToken) {
            EOFToken = [super allocWithZone:zone];
            return EOFToken;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}


- (id)copyWithZone:(NSZone *)zone {
    return self;
}


- (id)retain {
    return self;
}


- (oneway void)release {
    // do nothing
}


- (id)autorelease {
    return self;
}


- (NSUInteger)retainCount {
    return UINT_MAX; // denotes an object that cannot be released
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<TDTokenEOF %p>", self];
}


- (NSString *)debugDescription {
    return [self description];
}

@end

@interface TDToken ()
- (BOOL)isEqual:(id)rhv ignoringCase:(BOOL)ignoringCase;

@property (nonatomic, readwrite, getter=isNumber) BOOL number;
@property (nonatomic, readwrite, getter=isQuotedString) BOOL quotedString;
@property (nonatomic, readwrite, getter=isSymbol) BOOL symbol;
@property (nonatomic, readwrite, getter=isWord) BOOL word;
@property (nonatomic, readwrite, getter=isWhitespace) BOOL whitespace;
@property (nonatomic, readwrite, getter=isComment) BOOL comment;

@property (nonatomic, readwrite) CGFloat floatValue;
@property (nonatomic, readwrite, copy) NSString *stringValue;
@property (nonatomic, readwrite) TDTokenType tokenType;
@property (nonatomic, readwrite, copy) id value;
@end

@implementation TDToken

+ (TDToken *)EOFToken {
    return [TDTokenEOF instance];
}


+ (id)tokenWithTokenType:(TDTokenType)t stringValue:(NSString *)s floatValue:(CGFloat)n {
    return [[[self alloc] initWithTokenType:t stringValue:s floatValue:n] autorelease];
}


// designated initializer
- (id)initWithTokenType:(TDTokenType)t stringValue:(NSString *)s floatValue:(CGFloat)n {
    //NSParameterAssert(s);
    self = [super init];
    if (self) {
        self.tokenType = t;
        self.stringValue = s;
        self.floatValue = n;
        
        self.number = (TDTokenTypeNumber == t);
        self.quotedString = (TDTokenTypeQuotedString == t);
        self.symbol = (TDTokenTypeSymbol == t);
        self.word = (TDTokenTypeWord == t);
        self.whitespace = (TDTokenTypeWhitespace == t);
        self.comment = (TDTokenTypeComment == t);
    }
    return self;
}


- (void)dealloc {
    self.stringValue = nil;
    self.value = nil;
    [super dealloc];
}


- (NSUInteger)hash {
    return [stringValue hash];
}


- (BOOL)isEqual:(id)rhv {
    return [self isEqual:rhv ignoringCase:NO];
}


- (BOOL)isEqualIgnoringCase:(id)rhv {
    return [self isEqual:rhv ignoringCase:YES];
}


- (BOOL)isEqual:(id)rhv ignoringCase:(BOOL)ignoringCase {
    if (![rhv isMemberOfClass:[TDToken class]]) {
        return NO;
    }
    
    TDToken *tok = (TDToken *)rhv;
    if (tokenType != tok.tokenType) {
        return NO;
    }
    
    if (self.isNumber) {
        return floatValue == tok.floatValue;
    } else {
        if (ignoringCase) {
            return (NSOrderedSame == [stringValue caseInsensitiveCompare:tok.stringValue]);
        } else {
            return [stringValue isEqualToString:tok.stringValue];
        }
    }
}


- (id)value {
    if (!value) {
        id v = nil;
        if (self.isNumber) {
            v = [NSNumber numberWithFloat:floatValue];
        } else if (self.isQuotedString) {
            v = stringValue;
        } else if (self.isSymbol) {
            v = stringValue;
        } else if (self.isWord) {
            v = stringValue;
        } else if (self.isWhitespace) {
            v = stringValue;
        } else { // support for token type extensions
            v = stringValue;
        }
        self.value = v;
    }
    return value;
}


- (NSString *)debugDescription {
    NSString *typeString = nil;
    if (self.isNumber) {
        typeString = @"Number";
    } else if (self.isQuotedString) {
        typeString = @"Quoted String";
    } else if (self.isSymbol) {
        typeString = @"Symbol";
    } else if (self.isWord) {
        typeString = @"Word";
    } else if (self.isWhitespace) {
        typeString = @"Whitespace";
    } else if (self.isComment) {
        typeString = @"Comment";
    }
    return [NSString stringWithFormat:@"<%@ %C%@%C>", typeString, (unsigned short)0x00AB, self.value, (unsigned short)0x00BB];
}


- (NSString *)description {
    return stringValue;
}

@synthesize number;
@synthesize quotedString;
@synthesize symbol;
@synthesize word;
@synthesize whitespace;
@synthesize comment;
@synthesize floatValue;
@synthesize stringValue;
@synthesize tokenType;
@synthesize value;
@end

//
//  TDSymbolNode.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//


@interface TDSymbolNode ()
@property (nonatomic, readwrite, retain) NSString *ancestry;
@property (nonatomic, assign) TDSymbolNode *parent;  // this must be 'assign' to avoid retain loop leak
@property (nonatomic, retain) NSMutableDictionary *children;
@property (nonatomic) NSInteger character;
@property (nonatomic, retain) NSString *string;

- (void)determineAncestry;
@end

@implementation TDSymbolNode

- (id)initWithParent:(TDSymbolNode *)p character:(NSInteger)c {
    self = [super init];
    if (self) {
        self.parent = p;
        self.character = c;
        self.children = [NSMutableDictionary dictionary];

        // this private property is an optimization. 
        // cache the NSString for the char to prevent it being constantly recreated in -determinAncestry
        self.string = [NSString stringWithFormat:@"%C", (unsigned short)character];

        [self determineAncestry];
    }
    return self;
}


- (void)dealloc {
    parent = nil; // makes clang static analyzer happy
    self.ancestry = nil;
    self.string = nil;
    self.children = nil;
    [super dealloc];
}


- (void)determineAncestry {
    if (-1 == parent.character) { // optimization for sinlge-char symbol (parent is symbol root node)
        self.ancestry = string;
    } else {
        NSMutableString *result = [NSMutableString string];
        
        TDSymbolNode *n = self;
        while (-1 != n.character) {
            [result insertString:n.string atIndex:0];
            n = n.parent;
        }
        
        self.ancestry = [[result copy] autorelease]; // assign an immutable copy
    }
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<TDSymbolNode %@>", self.ancestry];
}

@synthesize ancestry;
@synthesize parent;
@synthesize character;
@synthesize string;
@synthesize children;
@end

//
//  TDSymbolRootNode.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//




@interface TDSymbolRootNode ()
- (void)addWithFirst:(NSInteger)c rest:(NSString *)s parent:(TDSymbolNode *)p;
- (void)removeWithFirst:(NSInteger)c rest:(NSString *)s parent:(TDSymbolNode *)p;
- (NSString *)nextWithFirst:(NSInteger)c rest:(TDReader *)r parent:(TDSymbolNode *)p;
@end

@implementation TDSymbolRootNode

- (id)init {
    self = [super initWithParent:nil character:-1];
    if (self) {
        
    }
    return self;
}


- (void)add:(NSString *)s {
    NSParameterAssert(s);
    if (s.length < 2) return;
    
    [self addWithFirst:[s characterAtIndex:0] rest:[s substringFromIndex:1] parent:self];
}


- (void)remove:(NSString *)s {
    NSParameterAssert(s);
    if (s.length < 2) return;
    
    [self removeWithFirst:[s characterAtIndex:0] rest:[s substringFromIndex:1] parent:self];
}


- (void)addWithFirst:(NSInteger)c rest:(NSString *)s parent:(TDSymbolNode *)p {
    NSParameterAssert(p);
    NSNumber *key = [NSNumber numberWithInteger:c];
    TDSymbolNode *child = [p.children objectForKey:key];
    if (!child) {
        child = [[TDSymbolNode alloc] initWithParent:p character:c];
        [p.children setObject:child forKey:key];
        [child release];
    }

    NSString *rest = nil;
    
    if (0 == s.length) {
        return;
    } else if (s.length > 1) {
        rest = [s substringFromIndex:1];
    }
    
    [self addWithFirst:[s characterAtIndex:0] rest:rest parent:child];
}


- (void)removeWithFirst:(NSInteger)c rest:(NSString *)s parent:(TDSymbolNode *)p {
    NSParameterAssert(p);
    NSNumber *key = [NSNumber numberWithInteger:c];
    TDSymbolNode *child = [p.children objectForKey:key];
    if (child) {
        NSString *rest = nil;
        
        if (0 == s.length) {
            return;
        } else if (s.length > 1) {
            rest = [s substringFromIndex:1];
            [self removeWithFirst:[s characterAtIndex:0] rest:rest parent:child];
        }
        
        [p.children removeObjectForKey:key];
    }
}


- (NSString *)nextSymbol:(TDReader *)r startingWith:(NSInteger)cin {
    NSParameterAssert(r);
    return [self nextWithFirst:cin rest:r parent:self];
}


- (NSString *)nextWithFirst:(NSInteger)c rest:(TDReader *)r parent:(TDSymbolNode *)p {
    NSParameterAssert(p);
    NSString *result = [NSString stringWithFormat:@"%C", (unsigned short)c];

    // this also works.
//    NSString *result = [[[NSString alloc] initWithCharacters:(const unichar *)&c length:1] autorelease];
    
    // none of these work.
    //NSString *result = [[[NSString alloc] initWithBytes:&c length:1 encoding:NSUTF8StringEncoding] autorelease];

//    NSLog(@"c: %d", c);
//    NSLog(@"string for c: %@", result);
//    NSString *chars = [[[NSString alloc] initWithCharacters:(const unichar *)&c length:1] autorelease];
//    NSString *utfs  = [[[NSString alloc] initWithUTF8String:(const char *)&c] autorelease];
//    NSString *utf8  = [[[NSString alloc] initWithBytes:&c length:1 encoding:NSUTF8StringEncoding] autorelease];
//    NSString *utf16 = [[[NSString alloc] initWithBytes:&c length:1 encoding:NSUTF16StringEncoding] autorelease];
//    NSString *ascii = [[[NSString alloc] initWithBytes:&c length:1 encoding:NSASCIIStringEncoding] autorelease];
//    NSString *iso   = [[[NSString alloc] initWithBytes:&c length:1 encoding:NSISOLatin1StringEncoding] autorelease];
//
//    NSLog(@"chars: '%@'", chars);
//    NSLog(@"utfs: '%@'", utfs);
//    NSLog(@"utf8: '%@'", utf8);
//    NSLog(@"utf16: '%@'", utf16);
//    NSLog(@"ascii: '%@'", ascii);
//    NSLog(@"iso: '%@'", iso);
    
    NSNumber *key = [NSNumber numberWithInteger:c];
    TDSymbolNode *child = [p.children objectForKey:key];
    
    if (!child) {
        if (p == self) {
            return result;
        } else {
            [r unread];
            return @"";
        }
    } 
    
    c = [r read];
    if (-1 == c) {
        return result;
    }
    
    return [result stringByAppendingString:[self nextWithFirst:c rest:r parent:child]];
}


- (NSString *)description {
    return @"<TDSymbolRootNode>";
}

@end


#endif
#pragma clang diagnostic pop
