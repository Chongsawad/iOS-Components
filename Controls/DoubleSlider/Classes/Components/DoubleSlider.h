//
//  DoubleSlider.h
//  Sweeter
//
//  Created by Dimitris on 23/06/2010.
//  Copyright 2010 locus-delicti.com. All rights reserved.
//

#define BACKGROUND_SLIDE_BAR @"bg-slide-bar.png"
#define BACKGROUND_HANDLE_BUTTON @"bt-handle-button.png"
#define BACKGROUND_ON_BAR_HOVER @"bg-slide-bar-ac.png"

#define kMinHandleDistance          0.0f
#define kBoundaryValueThreshold     0.001f
#define kMovingAnimationDuration    0.3f

static const float interval[4]     = {0.01f, 0.05f, 0.1f, 0.5f};
static const float sectionWidth[4] = {170.f, 58.f, 45.f, 7.f};
static const float sectionPos[4]   = {170.f, 228.f, 273.f, 280.f};

static const float sectionWidthForSingleSlider[4] = {170.f, 58.f, 45.f, 999.f};
static const float sectionPosForSingleSlider[4]   = {170.f, 228.f, 273.f, 999.f};

static float calValueSection(int s) {
    if (s == 0) {
        return 0.f;
    } else if (s == 1) {
        return interval[0] * sectionWidth[0];
    } else if (s == 2) {
        return interval[1] * sectionWidth[1] + interval[0] * sectionWidth[0];
    } else if (s == 3) {
        return interval[2] * sectionWidth[2] + interval[1] * sectionWidth[1] + interval[0] * sectionWidth[0];
    }
    return 0;
}

static float calValueSectionWithSingleSlider(int s) {
    if (s == 0) {
        return 0.f;
    } else if (s == 1) {
        return interval[0] * sectionWidthForSingleSlider[0];
    } else if (s == 2) {
        return interval[1] * sectionWidthForSingleSlider[1] + interval[0] * sectionWidthForSingleSlider[0];
    } else if (s == 3) {
        return interval[2] * sectionWidthForSingleSlider[2] + interval[1] * sectionWidthForSingleSlider[1] + interval[0] * sectionWidthForSingleSlider[0];
    }
    return 0;
}

@interface DoubleSlider : UIControl {
	float minSelectedValue;
	float maxSelectedValue;
	float minValue;
	float maxValue;
    float valueSpan;
    BOOL latchMin;
    BOOL latchMax;
	
	UIImageView *minHandle;
	UIImageView *maxHandle;
	
	float sliderBarHeight;
    float sliderBarWidth;
	
	CGColorRef bgColor;
    
    // ContentView
    UIView *contentView;
    
    // Single slider
    BOOL _singleSlider, _preciseValue;
    BOOL _snapToGrid, _snapCenter;
}

@property BOOL singleSlider, preciseValue;
@property (assign) BOOL snapToGrid, snapCenter;

@property float minSelectedValue;
@property float maxSelectedValue;

@property (nonatomic, retain) UIImageView *minHandle;
@property (nonatomic, retain) UIImageView *maxHandle;

- (id) initWithFrame:(CGRect)aFrame minValue:(float)minValue maxValue:(float)maxValue barHeight:(float)height;
- (id) initWithFrame:(CGRect)aFrame minValue:(float)aMinValue maxValue:(float)aMaxValue barHeight:(float)height singleSlider:(BOOL)singleSlider;

+ (id) doubleSlider;
- (void) moveSlidersToPosition:(NSNumber *)leftSlider:(NSNumber *)rightSlider animated:(BOOL)animated;
- (void)updateValues;

@end


/*
Improvements:
 - initWithWidth instead of frame?
 - do custom drawing below an overlay layer
 - add inner shadow to the background and shadow to handles in code
*/