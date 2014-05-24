//
//  SLInputView.m
//  soulight
//
//  Created by Ming Z. on 14-5-17.
//  Copyright (c) 2014年 i0xbean. All rights reserved.
//

#import "SLInputView.h"


#define kColorBlue              [UIColor colorWithRed:0.26 green:0.42 blue:0.95 alpha:1]

#define kTatBeginAlpha          0.3

typedef enum  {
    SLTatStatusNone,
    SLTatStatusBegin,
    SLTatStatusActive,
    SLTatStatusCanceling,
} SLTatStatus;

@interface SLInputView () {

}

@property (strong, nonatomic)       UIView *            tatView;

@property (assign, nonatomic)       SLTatStatus         tatStatus;
@property (strong, nonatomic)       NSTimer *           tatTimer;

@end

@implementation SLInputView

- (instancetype)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 320, 80)];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    
    CGPoint center = self.middlePoint;
    center.y += 8;
    
    UIColor *btnBgColor = [UIColor whiteColor];
    
    _recordBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kLayoutMainBtnWidth, kLayoutMainBtnWidth)];
    [_recordBtn setImage:[UIImage imageNamed:@"mic"] forState:UIControlStateNormal];
    [_recordBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
    _recordBtn.backgroundColor = btnBgColor;
    _recordBtn.layer.cornerRadius = _recordBtn.width/2;
    _recordBtn.center = center;
    _recordBtn.layer.borderWidth = 1;
    _recordBtn.y -= 10;
    [self addSubview:_recordBtn];
    
    _undoBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kLayoutBtnWidth, kLayoutBtnWidth)];
    [_undoBtn setImage:[UIImage imageNamed:@"undo"] forState:UIControlStateNormal];
    _undoBtn.backgroundColor = btnBgColor;
    _undoBtn.layer.cornerRadius = kLayoutBtnWidth/2;
    _undoBtn.layer.borderWidth = 1;
    _undoBtn.center = center;
    _undoBtn.x -= kLayoutInputMainBtnPadding + kLayoutInputBtnPadding*2;
    [self addSubview:_undoBtn];
    
    _redoBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kLayoutBtnWidth, kLayoutBtnWidth)];
    [_redoBtn setImage:[UIImage imageNamed:@"redo"] forState:UIControlStateNormal];
    _redoBtn.backgroundColor = btnBgColor;
    _redoBtn.layer.cornerRadius = kLayoutBtnWidth/2;
    _redoBtn.layer.borderWidth = 1;
    _redoBtn.center = center;
    _redoBtn.x -= kLayoutInputMainBtnPadding + kLayoutInputBtnPadding*1;
    [self addSubview:_redoBtn];
    
    
    float clearBtnDefaultX = center.x + kLayoutInputMainBtnPadding + kLayoutInputBtnPadding*1 - kLayoutBtnWidth/2;
    _clearBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kLayoutBtnWidth, kLayoutBtnWidth)];
    [_clearBtn setImage:[UIImage imageNamed:@"no"] forState:UIControlStateNormal];
    _clearBtn.backgroundColor = btnBgColor;
    _clearBtn.layer.cornerRadius = kLayoutBtnWidth/2;
    _clearBtn.layer.borderWidth = 1;
    _clearBtn.x = clearBtnDefaultX;
    _clearBtn.y = center.y - kLayoutBtnWidth/2;
    [self addSubview:_clearBtn];
    
    _hideKeyboardBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kLayoutBtnWidth, kLayoutBtnWidth)];
    [_hideKeyboardBtn setImage:[UIImage imageNamed:@"keyboard"] forState:UIControlStateNormal];
    [_hideKeyboardBtn setImage:[UIImage imageNamed:@"down"] forState:UIControlStateSelected];
    _hideKeyboardBtn.backgroundColor = btnBgColor;
    _hideKeyboardBtn.center = center;
    _hideKeyboardBtn.layer.cornerRadius = kLayoutBtnWidth/2;
    _hideKeyboardBtn.layer.borderWidth = 1;
    _hideKeyboardBtn.x += kLayoutInputMainBtnPadding + kLayoutInputBtnPadding*2;
    [self addSubview:_hideKeyboardBtn];
    
    UIPanGestureRecognizer *clearPan = [[UIPanGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        UIPanGestureRecognizer *ges = (UIPanGestureRecognizer*)sender;
        CGPoint p = [ges translationInView:self];
        
        if (state == UIGestureRecognizerStateBegan) {
            
        } else if (state == UIGestureRecognizerStateChanged) {
            
            _clearBtn.x = clearBtnDefaultX + p.x;
            if (p.x > kLayoutInputViewDeleteWidth) {
                _clearBtn.backgroundColor = [UIColor redColor];
            } else if (p.x < -kLayoutInputViewDeleteWidth) {
                _clearBtn.backgroundColor = [UIColor redColor];
            } else {
                _clearBtn.backgroundColor = btnBgColor;
            }
        } else if (state == UIGestureRecognizerStateEnded) {
            if (p.x > kLayoutInputViewDeleteWidth) {
                [self.delegate cleanButtonDidSwipeLeft];
            } else if (p.x < -kLayoutInputViewDeleteWidth) {
                [self.delegate cleanButtonDidSwipeRight];
            }
            
            [UIView animateWithDuration:0.2 animations:^{
                _clearBtn.x = clearBtnDefaultX;
            } completion:^(BOOL finished) {
                _clearBtn.backgroundColor = btnBgColor;
            }];
        }
    }];
    [_clearBtn addGestureRecognizer:clearPan];
    

    
    _recordBtn.showsTouchWhenHighlighted = YES;
    _undoBtn.showsTouchWhenHighlighted = YES;
    _redoBtn.showsTouchWhenHighlighted = YES;
    _clearBtn.showsTouchWhenHighlighted = YES;
    _hideKeyboardBtn.showsTouchWhenHighlighted = YES;
    
    _tatView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kLayoutBtnWidth)];
    _tatView.backgroundColor = kColorBlue;
    _tatView.userInteractionEnabled = NO;
    _tatView.center = center;
    _tatView.alpha = 0;
    [self addSubview:_tatView];
    
    self.backgroundColor = [UIColor clearColor];
    
    
    _tatTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(tatTimeUp) userInfo:nil repeats:YES];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGPoint p = self.middlePoint;
    p.y = _isAtBottom ? self.middleY - 2 : self.middleY + 8;
    _recordBtn.center = p;
    
    if (_isAtBottom) {
        _recordBtn.transform = CGAffineTransformMakeScale(1, 1);
    } else {
        _recordBtn.transform = CGAffineTransformMakeScale(0.8, 0.8);
    }
}


#pragma mark - touches actions

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    if (_tatStatus == SLTatStatusNone) {
        UITouch *t = touches.allObjects.lastObject;
        CGPoint p = [t locationInView:self];
        if ( ABS( p.x - 160) > 150 ) {
            self.tatStatus = SLTatStatusBegin;
        }
    } else if (_tatStatus == SLTatStatusCanceling) {
        self.tatStatus = SLTatStatusActive;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];

    if (_tatStatus == SLTatStatusBegin) {
        UITouch *t = touches.allObjects.lastObject;
        CGPoint p = [t locationInView:self];
        if ( ABS( p.x - 160) < 30 ) {
            self.tatStatus = SLTatStatusActive;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    DDLogVerbose(@"touchesEnded:%@|%@", nil, nil);

    if (_tatStatus == SLTatStatusActive) {
        self.tatStatus = SLTatStatusCanceling;
    } else {
        self.tatStatus = SLTatStatusNone;
    }
   
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesCancelled:touches withEvent:event];
    DDLogVerbose(@"touchesCancelled:%@|%@", nil, event);
    self.tatStatus = SLTatStatusNone;
}

#pragma mark - POJO

- (void)setTatStatus:(SLTatStatus)tatStatus
{
    _tatStatus = tatStatus;
    
    switch (_tatStatus) {
        case SLTatStatusNone:
            _tatView.alpha = 0;
            _undoBtn.userInteractionEnabled             = YES;
            _redoBtn.userInteractionEnabled             = YES;
            _recordBtn.userInteractionEnabled           = YES;
            _clearBtn.userInteractionEnabled            = YES;
            _hideKeyboardBtn.userInteractionEnabled     = YES;
            break;
        case SLTatStatusBegin:
            _tatView.alpha = kTatBeginAlpha;
            _undoBtn.userInteractionEnabled             = NO;
            _redoBtn.userInteractionEnabled             = NO;
            _recordBtn.userInteractionEnabled           = NO;
            _clearBtn.userInteractionEnabled            = NO;
            _hideKeyboardBtn.userInteractionEnabled     = NO;
            break;
        case SLTatStatusActive:
            _tatView.alpha = 1;
            break;
        case SLTatStatusCanceling: {
            float cancelingDuration = 1;
            _tatTimer.fireDate = [[NSDate date] dateByAddingTimeInterval:cancelingDuration];
            [UIView animateWithDuration:cancelingDuration animations:^{
                _tatView.alpha = 0;
            }];
            break;
        }
        default:
            break;
    }
}

#pragma mark - private

- (void)tatTimeUp
{
    if (_tatStatus == SLTatStatusCanceling) {
        self.tatStatus = SLTatStatusNone;
        [_tatTimer setFireDate:[NSDate distantFuture]];
    }
    
}

@end
