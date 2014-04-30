//
//  Hi5CardCell.m
//  Hi5
//
//  Created by Himanshu Tantia on 4/22/14.
//
//

#import "Hi5CardCell.h"
#import "UILabel+nsobject.h"

static UIColor *c;

@interface Hi5CardCell ()<UIGestureRecognizerDelegate>

@property (nonatomic,strong) UIPanGestureRecognizer *gestureRecognizer;
@property (nonatomic,assign) CGPoint originalCenter;
@property (nonatomic,assign) CGRect originalFrame;
@property (nonatomic,assign) BOOL canRelease;
@property (nonatomic,strong) UIColor *originalBackgroundColor;
@property (nonatomic,strong) Hi5CardCell *draggableView;
@end

@implementation Hi5CardCell

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    if (copy) {
        [copy setFrame:self.frame];
        [copy setOriginalCenter:self.originalCenter];
        [copy setOriginalFrame:self.originalFrame];
        [copy setRank:self.rank];
        [copy setCardType:self.cardType];
        UIImageView *imageViewCopy = [[UIImageView alloc] initWithFrame:self.imageView.frame];
        [imageViewCopy setImage:self.imageView.image];
        [imageViewCopy setContentMode:self.imageView.contentMode];
        [copy addSubview:imageViewCopy];
        [copy setName:[self.name copy]];
        if (![self.debugLabel isHidden]) {
            [copy addSubview:[self.debugLabel copy]];
        }
    }
    return copy;
}

-(void)dealloc
{
    [self removeGestureRecognizer:self.gestureRecognizer];
}

+(NSString *)reuseIdentifier
{
    return NSStringFromClass(self);
}

-(void)awakeFromNib
{
    if (!c) {
        c = [UIColor colorWithPatternImage:[UIImage imageNamed:@"empty+0.jpg"]];
    }
    [self.contentView setBackgroundColor:c];
    [self.contentView.layer setBorderWidth:0.5];
    self.canRelease = NO;
    self.gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(handlePanGesture:)];
    [self.gestureRecognizer setDelegate:self];
    [self addGestureRecognizer:self.gestureRecognizer];
    self.originalBackgroundColor = self.backgroundColor;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL shouldBegin = NO;
    if ([self.gestureRecognizers containsObject:self.gestureRecognizer]) {
        shouldBegin = YES;
        if ([self.delegate respondsToSelector:@selector(shouldDragCell:atIndexPath:)]) {
            shouldBegin = [self.delegate shouldDragCell:self
                                            atIndexPath:[(UICollectionView *)[self superview] indexPathForCell:self]];
        }
    }
    return shouldBegin;
}

- (Hi5CardCell *)createDraggableView
{
    self.draggableView = [self copy];
    [self.draggableView setAlpha:0.80];
    [self.draggableView setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
    [self.draggableView setBackgroundColor:[UIColor clearColor]];
    return self.draggableView;
}

-(void)handlePanGesture:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.originalCenter = self.center;
        self.originalFrame = self.frame;
        [[self superview] addSubview:[self createDraggableView]];
        [self.window bringSubviewToFront:self.draggableView];
    }
    
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self];
        self.draggableView.center = CGPointMake(_originalCenter.x + translation.x,
                                                _originalCenter.y + translation.y);
    }
    
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        NSIndexPath *targetCellIndexPath = [(UICollectionView *)[self superview] indexPathForItemAtPoint:self.draggableView.center];
        NSIndexPath *selfIndexPath = [(UICollectionView *)[self superview] indexPathForCell:self];
        
        _canRelease = ((targetCellIndexPath != nil) &&
                       (targetCellIndexPath != selfIndexPath));
        
        if (_canRelease) {
            [UIView animateWithDuration:0.4 animations:^{
                [self.draggableView setAlpha:0.0];
                [self.draggableView removeFromSuperview];
            } completion:^(BOOL finished) {
                [self.delegate willSwapCellAtIndexPath:selfIndexPath
                                   withCellAtIndexPath:targetCellIndexPath];
            }];
        }
        else
        {
            NSLog(@"InvalidDrop->IndexPath: %@",targetCellIndexPath);
            [UIView animateWithDuration:0.2 animations:^{
                self.draggableView.frame = self.originalFrame;
                [self.draggableView removeFromSuperview];
            }];
        }
    }
}

@end
