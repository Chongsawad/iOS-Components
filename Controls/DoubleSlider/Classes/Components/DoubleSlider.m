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

//define private methods
@interface DoubleSlider (PrivateMethods)
- (void)updateValues;
- (void)addToContext:(CGContextRef)context roundRect:(CGRect)rrect withRoundedCorner1:(BOOL)c1 corner2:(BOOL)c2 corner3:(BOOL)c3 corner4:(BOOL)c4 radius:(CGFloat)radius;
- (void)updateHandleImages;
@end


@implementation DoubleSlider

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

- (id) initWithFrame:(CGRect)aFrame minValue:(float)aMinValue maxValue:(float)aMaxValue barHeight:(float)height singleSlider:(BOOL)singleSlider
{
    self = [super initWithFrame:aFrame];
    if (self)
	{
		/*
         * Single slider
         */
        _singleSlider = singleSlider;
		
		if (aMinValue < aMaxValue) {
			minValue = aMinValue;
			maxValue = aMaxValue;
		}
		else {
			minValue = aMaxValue;
			maxValue = aMinValue;
		}
        valueSpan = maxValue - minValue;
		sliderBarHeight = height;
        sliderBarWidth = self.frame.size.width / self.transform.a;  //calculate the actual bar width by dividing with the cos of the view's angle

		UIImage *backgroundImage = [UIImage imageNamed:BACKGROUND_SLIDE_BAR];
		CGRect barRect = CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height);

		UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
		backgroundImageView.backgroundColor = [UIColor clearColor];
		backgroundImageView.frame = self.bounds;
		backgroundImageView.contentMode = UIViewContentModeCenter;
		backgroundImageView.userInteractionEnabled = NO;
		[self addSubview:backgroundImageView];
		[self sendSubviewToBack:backgroundImageView];

		if (!_singleSlider) {
			CGRect rangeBarRect = CGRectMake(0, (self.bounds.size.height - barRect.size.height) * 0.5f, barRect.size.width, barRect.size.height);
			highlightedRangeBarView = [[UIView alloc] initWithFrame:rangeBarRect];
			UIView *barImageView = [[UIView alloc] initWithFrame:barRect];
			barImageView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:BACKGROUND_ON_BAR_HOVER]];
			barImageView.clipsToBounds = YES;
			highlightedRangeBarView.clipsToBounds = YES;
			highlightedRangeBarView.userInteractionEnabled = NO;
			[highlightedRangeBarView addSubview:barImageView];
			[self insertSubview:highlightedRangeBarView aboveSubview:backgroundImageView];
		}

		
		/*
         * Min-Max button
         */
		self.minHandle = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:BACKGROUND_HANDLE_BUTTON] highlightedImage:[UIImage imageNamed:BACKGROUND_HANDLE_BUTTON]] autorelease];
        self.minHandle.frame = CGRectMake(0, 0, 30, self.bounds.size.height);
        self.minHandle.center = CGPointMake(sliderBarWidth * 0.2, SLIDER_OFFSET);
		self.minHandle.contentMode = UIViewContentModeCenter;
        self.minHandle.backgroundColor = [UIColor clearColor];
        self.minHandle.clipsToBounds = NO;
        
		[self addSubview:self.minHandle];
		
        self.maxHandle = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:BACKGROUND_HANDLE_BUTTON] highlightedImage:[UIImage imageNamed:BACKGROUND_HANDLE_BUTTON]] autorelease];
        self.maxHandle.frame = CGRectMake(0, 0, 30, self.bounds.size.height);
        self.maxHandle.center = CGPointMake(sliderBarWidth * 0.8, SLIDER_OFFSET);
		self.maxHandle.contentMode = UIViewContentModeCenter;
        self.maxHandle.backgroundColor = [UIColor clearColor];
        self.maxHandle.clipsToBounds = NO;
		
        if (!_singleSlider) {
            [self addSubview:self.maxHandle];
        }
		
		self.backgroundColor = [UIColor clearColor];
		
		//init
        latchMin = NO;
        latchMax = NO;
		[self updateValues];
        
        // contentView
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

- (id) initWithFrame:(CGRect)aFrame minValue:(float)aMinValue maxValue:(float)aMaxValue barHeight:(float)height
{
	return [self initWithFrame:aFrame minValue:aMinValue maxValue:aMaxValue barHeight:height singleSlider:NO];
}

- (void) moveSlidersToPosition:(NSNumber *)leftSlider: (NSNumber *)rightSlider animated:(BOOL)animated {
    CGFloat duration = animated ? kMovingAnimationDuration : 0.0;
    [UIView transitionWithView:self duration:duration options:UIViewAnimationOptionCurveLinear
                    animations:^(void){
                        self.minHandle.center = CGPointMake(sliderBarWidth * ((float)[leftSlider floatValue] / 100), SLIDER_OFFSET);
                        self.maxHandle.center = CGPointMake(sliderBarWidth * ((float)[rightSlider floatValue] / 100), SLIDER_OFFSET);
                        [self updateValues];
                        //force redraw
                        [self setNeedsDisplay];
                        //notify listeners
                        [self sendActionsForControlEvents:UIControlEventValueChanged];
                    }
                    completion:^(BOOL finished) {
                    }];
}


+ (id) doubleSlider
{
	return [[[self alloc] initWithFrame:CGRectMake(0., 0., 300., 40.) minValue:0.0 maxValue:100.0 barHeight:10.0] autorelease];
}

#pragma mark Touch tracking

-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
    if ( CGRectContainsPoint(self.minHandle.frame, touchPoint) ) {
		latchMin = YES;
	}
	else if ( CGRectContainsPoint(self.maxHandle.frame, touchPoint) ) {
		latchMax = YES;
	}
    [self updateHandleImages];
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchPoint = [touch locationInView:self];
    
	if ( latchMin || CGRectContainsPoint(self.minHandle.frame, touchPoint) ) {
        if (_singleSlider) {
            if (touchPoint.x < self.maxHandle.frame.origin.x && touchPoint.x > 0) {

                float point = MAX(touchPoint.x, self.minHandle.frame.size.width / 4);
                self.minHandle.center = CGPointMake(point, self.minHandle.center.y);
                
                [self updateValues];
            }
        } else if (touchPoint.x < self.maxHandle.frame.origin.x - self.maxHandle.frame.size.width / 2 && touchPoint.x > 0) {
            
            float point = MAX(touchPoint.x, self.minHandle.frame.size.width / 4);
            self.minHandle.center = CGPointMake(point + 1, self.minHandle.center.y);
            
            [self updateValues];	
        }
	}
	else if ( latchMax || CGRectContainsPoint(self.maxHandle.frame, touchPoint) ) {
		if (touchPoint.x - self.maxHandle.frame.size.width / 2 > self.minHandle.frame.origin.x + self.minHandle.frame.size.width) {
            float point = MIN((float)touchPoint.x, (float)(sliderBarWidth - self.maxHandle.frame.size.width / 4.f));
            self.maxHandle.center = CGPointMake(point - 1, self.maxHandle.center.y);
			[self updateValues];
		}
	}
	// Send value changed alert
	[self sendActionsForControlEvents:UIControlEventValueChanged];
    
	//redraw
	[self setNeedsDisplay];
	return YES;
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    latchMin = NO;
    latchMax = NO;
    [self updateHandleImages];
}

#pragma mark Custom Drawing

- (void) drawRect:(CGRect)rect
{
    if (_singleSlider == YES) {
        [super drawRect:rect];
        return;
    }
    
	//FIX: optimise and save some reusable stuff
	//	CGRect rect2 = CGRectMake(self.minHandle.frame.origin.x + self.minHandle.bounds.size.width, self.center.y - BACKGROUND_SLIDE_BAR_HEIGHT * 0.5, self.maxHandle.center.x - self.minHandle.center.x, BACKGROUND_SLIDE_BAR_HEIGHT);

	//    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
	//    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
	//    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
	//	
	//    CGContextRef context = UIGraphicsGetCurrentContext();
	//	CGContextClearRect(context, rect);
	//	
	//	CGRect rect1 = CGRectMake(0.0, 0.0, self.minHandle.center.x, sliderBarHeight);
	//	//	CGRect rect2 = CGRectMake(self.minHandle.center.x, 0.0, self.maxHandle.center.x - self.minHandle.center.x, sliderBarHeight);
	//	CGRect rect3 = CGRectMake(self.maxHandle.center.x, 0.0, sliderBarWidth - self.maxHandle.center.x, sliderBarHeight);
	//    
	//    CGContextSaveGState(context);
	//	
	//    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
	//    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
	//	
	//	//add the right rect
	//	[self addToContext:context roundRect:rect3 withRoundedCorner1:NO corner2:YES corner3:YES corner4:NO radius:5.0f];
	//	//add the left rect
	//	[self addToContext:context roundRect:rect1 withRoundedCorner1:YES corner2:NO corner3:NO corner4:YES radius:5.0f];
	//	
	//    CGContextClip(context);
	//    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
	//	
	//	CGGradientRelease(gradient), gradient = NULL;

	[super drawRect:rect];
}

- (void)addToContext:(CGContextRef)context roundRect:(CGRect)rrect withRoundedCorner1:(BOOL)c1 corner2:(BOOL)c2 corner3:(BOOL)c3 corner4:(BOOL)c4 radius:(CGFloat)radius
{	
	CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect);
	CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect);
	
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, c1 ? radius : 0.0f);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, c2 ? radius : 0.0f);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, c3 ? radius : 0.0f);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, c4 ? radius : 0.0f);
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
        if ([self.minHandle isEqual:handle]) {
            self.minSelectedValue += minValue;
            selectedValue = self.minSelectedValue;
            point = handle.frame.origin.x + handle.frame.size.width;
        } else {
            self.maxSelectedValue += minValue;
            self.maxSelectedValue = self.maxSelectedValue;
            point = handle.frame.origin.x - kMinHandleDistance;
        }
        
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
	self.minSelectedValue = minValue + (float)(self.minHandle.frame.origin.x + self.minHandle.frame.size.width) / sliderBarWidth * valueSpan;
    self.maxSelectedValue = minValue + (float)(self.maxHandle.frame.origin.x - kMinHandleDistance) / sliderBarWidth * valueSpan;

    if (_snapCenter) {
        self.minSelectedValue = minValue + self.minHandle.center.x / sliderBarWidth * valueSpan;
        self.maxSelectedValue = minValue + self.maxHandle.center.x / sliderBarWidth * valueSpan;
    }
    
    if (_preciseValue) {
        self.minSelectedValue = [self calculateInterval:self.minHandle];
        self.maxSelectedValue = [self calculateInterval:self.maxHandle];
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