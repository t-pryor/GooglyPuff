//
//  PhotoDisplayViewController.m
//  GCDTutorial
//
//  Created by A Magical Unicorn on A Sunday Night.
//  Copyright (c) 2014 Derek Selander. All rights reserved.
//

@import CoreImage;
@import QuartzCore;
#import "PhotoDetailViewController.h"
#import "PhotoManager.h"

const CGFloat kRetinaToEyeScaleFactor = 0.5f;
const CGFloat kFaceBoundsToEyeScaleFactor = 4.0f;

@interface PhotoDetailViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *photoScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (nonatomic, strong) UIImage *image;
@end

@implementation PhotoDetailViewController

//*****************************************************************************/
#pragma mark - LifeCycle
//*****************************************************************************/

// use dispatch_async when you need to perform a network-based or CPU intensive
// task in the background and not blcok the current thread

/*
 HOW AND WHEN TO USE THE VARIOUS QUEUES TYPES WITH dispatch_async
 Custom Serial Queue
 A good choice when you want to perform some background work serially and track it
 Eliminates resource contention since you know only one task at a time is executing
 If you need the data from a method, you must inline another block to retrieve it
 or consider using dispatch_sync
 
 *** Main Queue (Serial) ***
 This is a common choice to update the UI after completing work in a task on a concurrent queue.
 To do this, you code one block inside another
 If you're in the main queue and call dispatch_async, you can guarantee this new task
 will execute sometime after the current method finishes.
 
 Condurrent Queue: common choice to perfrom non-UI work in the background
 
 */



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    NSAssert(_image, @"Image not set; required to use view controller");
    self.photoImageView.image = _image;
    
    //Resize if neccessary to ensure it's not pixelated
    if (_image.size.height <= self.photoImageView.bounds.size.height &&
        _image.size.width <= self.photoImageView.bounds.size.width) {
        [self.photoImageView setContentMode:UIViewContentModeCenter];
    }
    
    // Move the work off the main thread and onto a global queue
    // block is submitted asynchronously-execution of the calling thread continues
    // lets viewDidLoad finish earlier on the main thread-loading time is faster
    // face detection processing is started and will finish at some later time
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIImage *overlayImage = [self faceOverlayImageFromImage:_image];
        // face detection processing is complete after preceeding line-new image generated
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fadeInNewImage:overlayImage];
        });
    });
}



//*****************************************************************************/
#pragma mark - Public Methods
//*****************************************************************************/

- (void)setupWithImage:(UIImage *)image
{
    self.image = image;
}

//*****************************************************************************/
#pragma mark - Private Methods
//*****************************************************************************/

- (UIImage *)faceOverlayImageFromImage:(UIImage *)image
{
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    // Get features from the image
    CIImage* newImage = [CIImage imageWithCGImage:image.CGImage];
    
    NSArray *features = [detector featuresInImage:newImage];
    
    UIGraphicsBeginImageContext(image.size);
    CGRect imageRect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
    
    //Draws this in the upper left coordinate system
    [image drawInRect:imageRect blendMode:kCGBlendModeNormal alpha:1.0f];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (CIFaceFeature *faceFeature in features) {
        CGRect faceRect = [faceFeature bounds];
        CGContextSaveGState(context);
        
        // CI and CG work in different coordinate systems, we should translate to
        // the correct one so we don't get mixed up when calculating the face position.
        CGContextTranslateCTM(context, 0.0, imageRect.size.height);
        CGContextScaleCTM(context, 1.0f, -1.0f);
        
        if ([faceFeature hasLeftEyePosition]) {
            CGPoint leftEyePosition = [faceFeature leftEyePosition];
            CGFloat eyeWidth = faceRect.size.width / kFaceBoundsToEyeScaleFactor;
            CGFloat eyeHeight = faceRect.size.height / kFaceBoundsToEyeScaleFactor;
            CGRect eyeRect = CGRectMake(leftEyePosition.x - eyeWidth/2.0f,
                                        leftEyePosition.y - eyeHeight/2.0f,
                                        eyeWidth,
                                        eyeHeight);
            [self drawEyeBallForFrame:eyeRect];
        }
        
        if ([faceFeature hasRightEyePosition]) {
            CGPoint leftEyePosition = [faceFeature rightEyePosition];
            CGFloat eyeWidth = faceRect.size.width / kFaceBoundsToEyeScaleFactor;
            CGFloat eyeHeight = faceRect.size.height / kFaceBoundsToEyeScaleFactor;
            CGRect eyeRect = CGRectMake(leftEyePosition.x - eyeWidth / 2.0f,
                                        leftEyePosition.y - eyeHeight / 2.0f,
                                        eyeWidth,
                                        eyeHeight);
            [self drawEyeBallForFrame:eyeRect];
        }
    
        CGContextRestoreGState(context);
    }
    
    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return overlayImage;
}

- (CGFloat)faceRotationInRadiansWithLeftEyePoint:(CGPoint)startPoint rightEyePoint:(CGPoint)endPoint;
{
    CGFloat deltaX = endPoint.x - startPoint.x;
    CGFloat deltaY = endPoint.y - startPoint.y;
    CGFloat angleInRadians = atan2f(deltaY, deltaX);
    
    return angleInRadians;
}

- (void)drawEyeBallForFrame:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddEllipseInRect(context, rect);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);
    
    CGFloat x, y, eyeSizeWidth, eyeSizeHeight;
    eyeSizeWidth = rect.size.width * kRetinaToEyeScaleFactor;
    eyeSizeHeight = rect.size.height * kRetinaToEyeScaleFactor;
    
    x = arc4random_uniform((rect.size.width - eyeSizeWidth));
    y = arc4random_uniform((rect.size.height - eyeSizeHeight));
    x += rect.origin.x;
    y += rect.origin.y;
    
    CGFloat eyeSize = MIN(eyeSizeWidth, eyeSizeHeight);
    CGRect eyeBallRect = CGRectMake(x, y, eyeSize, eyeSize);
    CGContextAddEllipseInRect(context, eyeBallRect);
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillPath(context);
}

- (void)fadeInNewImage:(UIImage *)newImage
{
    UIImageView *tmpImageView = [[UIImageView alloc] initWithImage:newImage];
    tmpImageView.contentMode = self.photoImageView.contentMode;
    tmpImageView.frame = self.photoImageView.bounds;
    tmpImageView.alpha = 0.0f;
    [self.photoImageView addSubview:tmpImageView];
    
    [UIView animateWithDuration:0.75f animations:^{
        tmpImageView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        self.photoImageView.image = newImage;
        [tmpImageView removeFromSuperview];
    }];
}

//*****************************************************************************/
#pragma mark - UIScrollViewDelegate
//*****************************************************************************/

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.photoImageView;
}
@end

