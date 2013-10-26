//
//  DoubleSlider.m
//  Sweeter
//
//  Created by Dimitris on 23/06/2010.
//  Copyright 2010 locus-delicti.com. All rights reserved.
//

#import "DoubleSlider.h"

#define SLIDER_OFFSET 30
//create the gradient
static const CGFloat colors [] = { 
	0.6, 0.6, 1.0, 1.0, 
	0.0, 0.0, 1.0, 1.0
};

typedef enum : NSUInteger {
	BKDSlideDirectionLeft,
	BKDSlideDirectionRight,
} BKDSlideDirection;

//define private methods
@interface DoubleSlider (PrivateMethods)

- (void)updateValues;
- (void)updateHandleImages;

@end

@implementation DoubleSlider {
	CGRect originalLeftHandleRect, originalRightHandleRect;
}

@synthesize minSelectedValue, maxSelectedValue;
@synthesize minHandle, maxHandle;

- (void) dealloc
{
	CGColorRelease(bgColor);
	self.minHandle = nil;
	self.maxHandle = nil;
	[super dealloc];
}

#pragma mark Object initialization

- (id) initWithFrame:(CGRect)aFrame
            minValue:(float)aMinValue
            maxValue:(float)aMaxValue
           barHeight:(float)height
        singleSlider:(BOOL)singleSlider
{
    self = [super initWithFrame:aFrame];
    if (self)
	{
		//
        // Single slider
        //
        _singleSlider = singleSlider;
        minValue = MIN(aMinValue, aMaxValue);
        maxValue = MAX(aMinValue, aMaxValue);
        valueSpan = maxValue - minValue;
        sliderBarHeight = height;
        sliderBarWidth = self.frame.size.width;
        originalLeftHandleRect = originalRightHandleRect = CGRectMake(0, 0, 28, CGRectGetHeight(self.bounds));

		//
        // Common Style
        //
        UIImage *backgroundImage = [UIImage imageNamed:BACKGROUND_SLIDE_BAR];
        CGRect barRect = CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height);
        UIImageView *bgView = [[UIImageView alloc] initWithImage:backgroundImage];
        bgView.backgroundColor = [UIColor clearColor];
        bgView.frame = self.bounds;
        bgView.contentMode = UIViewContentModeCenter;
        bgView.opaque = NO;
        [self addSubview:bgView];
        [self sendSubviewToBack:bgView];
        [self setBackgroundColor:[UIColor clearColor]];

		if (!_singleSlider) {
            CGRect rangeBarRect = CGRectMake(0,(CGRectGetHeight(self.bounds) - CGRectGetHeight(barRect)) * 0.5f
                                             , CGRectGetWidth(barRect)
                                             , CGRectGetHeight(barRect));
            UIView *barImageView = [[UIView alloc] initWithFrame:barRect];
            barImageView.backgroundColor = [UIColor colorWithPatternImage:
                                            [UIImage imageNamed:BACKGROUND_ON_BAR_HOVER]];
            barImageView.clipsToBounds = YES;

            highlightedRangeBarView = [[UIView alloc] initWithFrame:rangeBarRect];
            highlightedRangeBarView.clipsToBounds = YES;
            highlightedRangeBarView.userInteractionEnabled = NO;
            [highlightedRangeBarView addSubview:barImageView];
            [self insertSubview:highlightedRangeBarView aboveSubview:bgView];
        }

		//
        // Left
        //
        self.minHandle = [[[UIImageView alloc] initWithImage:
                           [UIImage imageNamed:BACKGROUND_HANDLE_BUTTON]] autorelease];
        self.minHandle.frame = CGRectMake(0, 0, 40, CGRectGetHeight(self.bounds));
        self.minHandle.contentMode = UIViewContentModeCenter;
		//self.minHandle.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.4f];
        [self addSubview:self.minHandle];

        //
        // Right
        //
        self.maxHandle = [[[UIImageView alloc] initWithImage:
                           [UIImage imageNamed:BACKGROUND_HANDLE_BUTTON]] autorelease];
        self.maxHandle.frame = CGRectMake(0, 0, 40, CGRectGetHeight(self.bounds));
        self.maxHandle.contentMode = UIViewContentModeCenter;
		//self.maxHandle.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.4f];
        if (!_singleSlider) {
            [self addSubview:self.maxHandle];
        }

		//init
		latchMin = NO;
        latchMax = NO;
		[self updateValues];

		//
        // ContentView
        //
        contentView = [[UIView alloc] initWithFrame:self.bounds];
        contentView.backgroundColor = [UIColor clearColor];
		contentView.userInteractionEnabled = NO;
        contentView.opaque = NO;
        [self addSubview:contentView];
        [self bringSubviewToFront:self.maxHandle];
        [self bringSubviewToFront:self.minHandle];
	}
	return self;
}

- (id)initWithFrame:(CGRect)aFrame
			minValue:(float)aMinValue
			maxValue:(float)aMaxValue
		   barHeight:(float)height
{
	return [self initWithFrame:aFrame
					  minValue:aMinValue
					  maxValue:aMaxValue
					 barHeight:height
				  singleSlider:NO];
}

- (void)moveSlidersToPosition:(NSNumber *)leftSlider
							 :(NSNumber *)rightSlider
					 animated:(BOOL)animated {

    CGFloat duration = animated ? kMovingAnimationDuration : 0.0;
    [UIView transitionWithView:self
					  duration:duration
					   options:UIViewAnimationOptionCurveLinear
                    animations:^(void){
                        self.minHandle.center = CGPointMake(sliderBarWidth * ((float)[leftSlider floatValue] / 100) + CGRectGetWidth(self.minHandle.frame) / 2, SLIDER_OFFSET);
                        self.maxHandle.center = CGPointMake(sliderBarWidth * ((float)[rightSlider floatValue] / 100) - CGRectGetWidth(self.maxHandle.frame) / 2, SLIDER_OFFSET);
                    }
                    completion:^(BOOL finished) {
						[self updateValues];
                        [self setNeedsDisplay];
                        [self sendActionsForControlEvents:UIControlEventValueChanged];
                    }];
}


+ (id)doubleSlider
{
	return [[[self alloc] initWithFrame:CGRectMake(0., 0., 300., 40.) minValue:0.0 maxValue:100.0 barHeight:10.0] autorelease];
}

#pragma mark Touch tracking

-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
	touchPoint.y = self.minHandle.frame.origin.y;

    if (touchPoint.x < CGRectGetMaxX(self.minHandle.frame)) {
		latchMin = YES;

	} else if (touchPoint.x >= CGRectGetMinX(self.maxHandle.frame)) {
		latchMax = YES;
	}


	[self updateHandleImages];
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchPoint = [touch locationInView:self]; UIView *handle;
	touchPoint.y = self.minHandle.frame.origin.y;
	if (latchMin) {
		handle = self.minHandle;
        if (_singleSlider) {
			//
			// Single Slider
			//
            if (touchPoint.x < self.maxHandle.frame.origin.x && touchPoint.x > 0) {
                float point = MAX(touchPoint.x, handle.frame.size.width / 4);
                handle.center = CGPointMake(point, handle.center.y);
                [self updateValues];
				[self sendActionsForControlEvents:UIControlEventValueChanged];
            }
        } else {
			//
			// Move Left HandleView
			//
			[self bkd_moveHandle:handle
				toTouchPoint:touchPoint
				   direction:BKDSlideDirectionLeft];
			[self updateValues];
			[self sendActionsForControlEvents:UIControlEventValueChanged];
		}

	} else if (latchMax) {
		handle = self.maxHandle;

		//
		// Move Right HandleView
		//
		[self bkd_moveHandle:handle
				 toTouchPoint:touchPoint
		 direction:BKDSlideDirectionRight];

		[self updateValues];
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}

	return YES;
}

- (void)bkd_moveHandle:(UIView *)handle
	  toTouchPoint:(CGPoint)touchPoint
		 direction:(BKDSlideDirection)direction
{
	CGRect handleRect; handleRect = handle.frame;

	CGFloat limitScopeX, preferredX;
	if (direction == BKDSlideDirectionLeft) {
		limitScopeX = (CGRectGetWidth(originalLeftHandleRect) - CGRectGetWidth(handleRect)) / 2;
		preferredX = touchPoint.x - (CGRectGetWidth(handleRect) - CGRectGetWidth(originalLeftHandleRect)) / 2 - CGRectGetWidth(originalLeftHandleRect) / 2;
		handleRect.origin.x = MAX(limitScopeX, preferredX);

	} else {
		limitScopeX = CGRectGetWidth(self.frame) - CGRectGetWidth(handleRect) + (CGRectGetWidth(handleRect) - CGRectGetWidth(originalRightHandleRect)) / 2;


		preferredX = touchPoint.x - ((CGRectGetWidth(handleRect) - CGRectGetWidth(originalRightHandleRect)) / 2)
		- (CGRectGetWidth(originalRightHandleRect) / 2);
		handleRect.origin.x = MIN(limitScopeX, preferredX);
	}

	handleRect = [self bkd_collisionHandle:handle
								  fromRect:handle.frame
									toRect:handleRect
							   toDirection:direction];

	handle.frame = handleRect;
}

- (CGRect)bkd_collisionHandle:(UIView *)handle
					 fromRect:(CGRect)originalRect
					   toRect:(CGRect)handleRect
				  toDirection:(BKDSlideDirection)direction
{
	if (direction == BKDSlideDirectionLeft) {
		CGFloat borderLeftPoint = CGRectGetMidX(handleRect) + CGRectGetWidth(originalLeftHandleRect) / 2;
		CGFloat borderRightPoint = CGRectGetMidX(self.maxHandle.frame) - CGRectGetWidth(originalRightHandleRect) / 2;
		if (borderLeftPoint - 2.5f >= borderRightPoint) {
			// Restore to old value
			handleRect.origin.x = originalRect.origin.x;
		}

	} else {
		CGFloat borderLeftPoint = CGRectGetMidX(self.minHandle.frame) + CGRectGetWidth(originalLeftHandleRect) / 2;
		CGFloat borderRightPoint = CGRectGetMidX(handleRect) - CGRectGetWidth(originalRightHandleRect) / 2;
		if (borderLeftPoint - 2.5f >= borderRightPoint) {
			// Restore to old value
			handleRect.origin.x = originalRect.origin.x;
		}
	}

	return handleRect;
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    latchMin = NO;
    latchMax = NO;
    [self updateHandleImages];
}

#pragma mark Helper

- (float)calculateInterval:(UIView *)handle
{
    float selectedValue, point;
    if (_singleSlider) {
        self.minSelectedValue += minValue;
        selectedValue = self.minSelectedValue;
        point = handle.frame.origin.x - kMinHandleDistance;
        
        if (point < sectionPosForSingleSlider[0]) {
            selectedValue = point * interval[0];
            //NSLog(@"[0][%.2f] min selected value %f", point, selectedValue);
            
        } else if (point < sectionPosForSingleSlider[1]) {
            selectedValue = calValueSectionWithSingleSlider(1) + (point - sectionPosForSingleSlider[0]) * interval[1];
            //NSLog(@"[1][%.2f] min selected value %f", point, selectedValue);
            
        } else if (point < sectionPosForSingleSlider[2]) {
            selectedValue = calValueSectionWithSingleSlider(2) + (point - sectionPosForSingleSlider[1]) * interval[2];
            //NSLog(@"[2][%.2f] min selected value %f", point, selectedValue);
            
        } else if (point < sectionPosForSingleSlider[3]) {
            selectedValue = calValueSectionWithSingleSlider(3) + (point - sectionPosForSingleSlider[2]) * interval[3];
            //NSLog(@"[3][%.2f] min selected value %f", point, selectedValue);
            
        } else {
            //NSLog(@"[4] min selected value not in any range %f", point);
        }
        
    } else {
		CGFloat insetRange, originWidth;
        if ([self.minHandle isEqual:handle]) {
			//
			// Calculate outbound frame
			//
			insetRange = (CGRectGetWidth(handle.frame) - CGRectGetWidth(originalLeftHandleRect)) / 2.0f;
			originWidth = CGRectGetWidth(originalLeftHandleRect) / 2.0f;

			//
			// Translate to point
			//
            self.minSelectedValue += minValue;
            selectedValue = self.minSelectedValue;
            point = handle.center.x + originWidth;

        } else {
			//
			// Calculate outbound frame
			//
			insetRange = (CGRectGetWidth(handle.frame) - CGRectGetWidth(originalRightHandleRect)) / 2.0f;
			originWidth = CGRectGetWidth(originalRightHandleRect) / 2.0f;

			//
			// Translate to point
			//
            self.maxSelectedValue += minValue;
			selectedValue = self.maxSelectedValue;
            point = handle.center.x - originWidth + 2;
        }

		//
		// Translate to real value
		//
		if (point < sectionPos[0]) {
            selectedValue = point * interval[0];
            //NSLog(@"[0][%.2f] min selected value %f", point, selectedValue);
            
        } else if (point < sectionPos[1]) {
            selectedValue = calValueSection(1) + (point - sectionPos[0]) * interval[1];
            //NSLog(@"[1][%.2f] min selected value %f", point, selectedValue);
            
        } else if (point < sectionPos[2]) {
            selectedValue = calValueSection(2) + (point - sectionPos[1]) * interval[2];
            //NSLog(@"[2][%.2f] min selected value %f", point, selectedValue);
            
        } else if (point < sectionPos[3]) {
            selectedValue = calValueSection(3) + (point - sectionPos[2]) * interval[3];
            //NSLog(@"[3][%.2f] min selected value %f", point, selectedValue);
            
        } else if (point < sectionPos[4]) {
            selectedValue = calValueSection(4) + (point - sectionPos[3]) * interval[4];
            //NSLog(@"[3][%.2f] min selected value %f", point, selectedValue);

        } else {
            //NSLog(@"[4] min selected value not in any range %f", point);
        }
    }
    
    return selectedValue;
}

- (void)updateHandleImages
{
    self.minHandle.highlighted = latchMin;
    self.maxHandle.highlighted = latchMax;
}

- (void)updateValues
{
	if (_preciseValue) {
        self.minSelectedValue = [self calculateInterval:self.minHandle];
        self.maxSelectedValue = [self calculateInterval:self.maxHandle];
    } else {
		self.minSelectedValue = minValue + self.minHandle.center.x / sliderBarWidth * valueSpan;
		self.maxSelectedValue = minValue + self.maxHandle.center.x / sliderBarWidth * valueSpan;
	}

    //snap to min value
    if (self.minSelectedValue < minValue + kBoundaryValueThreshold * valueSpan) {
        self.minSelectedValue = minValue;
    }
    
    //snap to max value
    if (self.maxSelectedValue > maxValue - kBoundaryValueThreshold * valueSpan) {
        self.maxSelectedValue = maxValue;
    }

	// check min <= max
	if (self.minSelectedValue > self.maxSelectedValue) {
		self.minSelectedValue = self.maxSelectedValue;
	}
}

@end