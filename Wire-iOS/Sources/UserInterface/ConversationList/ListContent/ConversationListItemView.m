// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "ConversationListItemView.h"

#import <PureLayout/PureLayout.h>

#import "ConversationListIndicator.h"
#import "ListItemRightAccessoryView.h"
#import "WAZUIMagicIOS.h"
#import "Constants.h"
#import "UIColor+WAZExtensions.h"

#import "UIView+Borders.h"
#import "zmessaging+iOS.h"

NSString * const ConversationListItemDidScrollNotification = @"ConversationListItemDidScrollNotification";



@interface ConversationListItemView ()

@property (nonatomic, strong, readwrite) ConversationListIndicator *statusIndicator;
@property (nonatomic, strong) ListItemRightAccessoryView *rightAccessory;
@property (nonatomic, strong) UILabel *titleField;
@property (nonatomic, strong) UILabel *subtitleField;
@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, assign) BOOL enableSubtitles;
@property (nonatomic, assign) BOOL hasCreatedInitialConstraints;

@property (nonatomic, strong) NSLayoutConstraint *titleBottomMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *rightAccessoryWidthConstraint;

@end



@implementation ConversationListItemView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupConversationListItemView];
    }
    return self;
}

- (instancetype)initWithSubtitlesEnabled:(BOOL)subtitlesEnabled
{
    self = [super init];
    if (self) {
        self.enableSubtitles = subtitlesEnabled;
        [self setupConversationListItemView];
    }
    return self;
}

- (void)setupConversationListItemView
{
    _selectionColor = [UIColor accentColor];
    
    self.titleField = [[UILabel alloc] initForAutoLayout];
    self.titleField.numberOfLines = 1;
    self.titleField.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleField.adjustsFontForContentSizeCategory = YES;
    self.titleField.font = [[UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"] dynamic];

    [self addSubview:self.titleField];
    
    self.statusIndicator = [[ConversationListIndicator alloc] initForAutoLayout];
    [self addSubview:self.statusIndicator];
    
    self.rightAccessory = [[ListItemRightAccessoryView alloc] initForAutoLayout];
    [self addSubview:self.rightAccessory];

    if (self.enableSubtitles) {
        [self createSubtitleField];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(otherConversationListItemDidScroll:)
                                                 name:ConversationListItemDidScrollNotification
                                               object:nil];
}

// Only called when enableSubtitles is set to YES
- (void)createSubtitleField
{
    self.subtitleField = [[UILabel alloc] initForAutoLayout];

    self.titleBottomMarginConstraint.constant = -42;

    self.subtitleField.font = [UIFont fontWithMagicIdentifier:@"list.subtitle.font"];
    self.subtitleField.textColor = [UIColor colorWithMagicIdentifier:@"list.subtitle.color"];
    self.subtitleField.numberOfLines = 2;
    [self addSubview:self.subtitleField];

    self.lineView = [[UIView alloc] initForAutoLayout];
    self.lineView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.07];
    [self addSubview:self.lineView];
}

- (void)updateConstraints
{
    if (! self.hasCreatedInitialConstraints) {
        self.hasCreatedInitialConstraints = YES;
        
        CGFloat leftMargin = [WAZUIMagic floatForIdentifier:@"list.left_margin"];
        [self.statusIndicator autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeRight];
        [self.statusIndicator autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.titleField];
        
        [self.titleField autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self withOffset:leftMargin];
        [self.titleField autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.rightAccessory withOffset:0.0];
        self.titleBottomMarginConstraint = [self.titleField autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:18.0f];

        [self.rightAccessory autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:18.0];
        [self.rightAccessory autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.rightAccessory autoSetDimension:ALDimensionHeight toSize:28.0f];
        self.rightAccessoryWidthConstraint = [self.rightAccessory autoSetDimension:ALDimensionWidth toSize:0.0f];
        [self updateRightAccessoryWidth];
        
        if (self.enableSubtitles) {
            [self.subtitleField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleField withOffset:2];
            [self.subtitleField autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.titleField];
            [self.subtitleField autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.titleField];
            
            [self.lineView autoSetDimension:ALDimensionHeight toSize:1.0];
            [self.lineView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
            [self.lineView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self withOffset:-35.0];
            [self.lineView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.titleField];
        }
    }
    
    [super updateConstraints];
}

- (void)setTitleText:(NSString *)titleText
{
    _titleText = titleText;
    self.titleField.text = titleText;
    self.titleField.textColor = [self colorForSelectionState:self.selected];
}

- (void)setSubtitleText:(NSString *)subtitleText
{
    if (self.enableSubtitles) {
        _subtitleText = subtitleText;
        self.subtitleField.text = subtitleText ? subtitleText : @"";
    }
}

- (void)setSelectionColor:(UIColor *)selectionColor
{
    _selectionColor = selectionColor;
    [self updateAppearance];
}

- (CGFloat)titleBottomMargin
{
    return self.titleBottomMarginConstraint.constant;
}

- (void)setTitleBottomMargin:(CGFloat)titleBottomMargin
{
    self.titleBottomMarginConstraint.constant = titleBottomMargin;
}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected) {
        _selected = selected;
        [self updateAppearance];
    }
}

- (void)setRightAccessoryType:(ConversationListRightAccessoryType)rightAccessoryType
{
    if (_rightAccessoryType == rightAccessoryType) {
        return;
    }
    
    _rightAccessoryType = rightAccessoryType;
    
    self.rightAccessory.accessoryType = rightAccessoryType;
    [self updateRightAccessoryWidth];
}

- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset notify:(BOOL)notify
{
    _visualDrawerOffset = visualDrawerOffset;
    if (notify && _visualDrawerOffset != visualDrawerOffset) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ConversationListItemDidScrollNotification object:self];
    }
}

- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset
{
    [self setVisualDrawerOffset:visualDrawerOffset notify:YES];
}

- (void)updateRightAccessoryWidth
{
    BOOL muteVoiceAndLandscape = (self.rightAccessoryType == ConversationListRightAccessoryMuteVoiceButton  && IS_IPAD_LANDSCAPE_LAYOUT);
    
    if (muteVoiceAndLandscape) {
        // If we are showing the mute button and in landscape, don't show the button
        self.rightAccessoryWidthConstraint.constant = 0;
        [self.rightAccessory setHidden:YES];
    }
    else if (self.rightAccessoryType == ConversationListRightAccessoryNone) {
        self.rightAccessoryWidthConstraint.constant = 0;
        [self.rightAccessory setHidden:YES];
    }
    else {
        [self.rightAccessory setHidden:NO];
        self.rightAccessoryWidthConstraint.constant = 28.0f;
    }
}

- (void)updateForCurrentOrientation
{
    [self updateRightAccessoryWidth];
}

- (void)updateRightAccessoryAppearance
{
    [self.rightAccessory updateButtonStates];
}

- (void)updateAppearance
{
    UIColor *textColor = [self colorForSelectionState:self.selected];
    
    self.titleField.text = self.titleText;
    self.titleField.textColor = textColor;

    self.subtitleField.textColor = [textColor colorWithAlphaComponent:0.7];
    self.statusIndicator.foregroundColor = self.selectionColor;
}

- (UIColor *)colorForSelectionState:(BOOL)selected
{
    return selected ? self.selectionColor : [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"];
}

#pragma mark - Observer

- (void)otherConversationListItemDidScroll:(NSNotification *)notification
{
    if ([notification.object isEqual:self]) {
        return;
    }
    else {
        ConversationListItemView *otherItem = notification.object;

        CGFloat fraction = 1.0f;
        if (self.bounds.size.width != 0) {
            fraction = (1.0f - otherItem.visualDrawerOffset / self.bounds.size.width);
        }

        if (fraction > 1.0f) {
            fraction = 1.0f;
        }
        else if (fraction < 0.0f) {
            fraction = 0.0f;
        }
        self.alpha = 0.35f + fraction * 0.65f;
    }
}

@end

