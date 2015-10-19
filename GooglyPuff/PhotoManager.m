//  PhotoManager.m
//  PhotoFilter
//
//  Created by A Magical Unicorn on A Sunday Night.
//  Copyright (c) 2014 Derek Selander. All rights reserved.
//

@import CoreImage;
@import AssetsLibrary;
#import "PhotoManager.h"

@interface PhotoManager ()

@property (nonatomic, strong, readonly) NSMutableArray *photosArray;
@property (nonatomic, strong) dispatch_queue_t concurrentPhotoQueue;
@end

@implementation PhotoManager

+ (instancetype)sharedManager
{
    static PhotoManager *sharedPhotoManager = nil;
    static dispatch_once_t onceToken;
    
    // dispatch_once executes a block and only once, in a thread-safe manner
    // different threads that try to access the critical section (the code passed into dispatch_once)
    // while a thread is already in this section are blocked until the critical section completes
    
     dispatch_once(&onceToken, ^{
         sharedPhotoManager = [[PhotoManager alloc] init];
         sharedPhotoManager->_photosArray = [NSMutableArray array];
             
         //why not sharedPhotoManager.photosArray?
         // http://stackoverflow.com/questions/15439623/when-where-the-arrow-notation-should-be-used-in-objective-c
         
         sharedPhotoManager->_concurrentPhotoQueue = dispatch_queue_create("com.selander.GooglyPuff.photoQueue", DISPATCH_QUEUE_CONCURRENT);
         
     });
    
     return sharedPhotoManager;
    
}

//*****************************************************************************/
#pragma mark - Unsafe Setter/Getters
//*****************************************************************************/

// READERS-WRITERS PROBLEM


/* 
    BARRIER FUNCTIONS
    
    *Custom Serial Queue*
    Barriers won't do anything helpful since a serial queue executes
    one op at a time anyway
 
    *Global Concurrent Queue*
    Probably not the best idea to use here since other systes might
    be using the queues and you don't want to monopolize them for 
    your own purposes
 
    *Custom Concurrent Queue*
    Great choice for atomic or critical areas of code
    Anything you're setting or instantiating that needs to be
    thread safe is a great choice for a barrier
 
 
 
 */

/*
    WHERE AND WHEN TO USE dispatch_sync
 
    *Custom Serial Queue*
    Be careful: if you're running in a queue and call dispatch_sync targeting
    the same queue, you will definitely create a deadlock
 
    *Main Queue (Serial)
    Be careful: can cause deadlock-same reasons as above
 
    *Concurrent Queue: Good candidate to sync work through
    dispatch barriers or when waiting for a task to complete
    so you can perform further processing
 
 
 
 
 
 */

- (NSArray *)photos
{
    
    
    //__block variable written outside dispatch_sync scope in order to use
    // the processed object returned outside the dispatch_sync function
    __block NSArray *array;
    
    
    // to ensure thread safety with the writer, you need to perform the
    // read on the concurrentPhotoQueue
    // need to return from the function, so you can't dispatch asynchronously
    // return
    dispatch_sync(self.concurrentPhotoQueue, ^{
        array = [NSArray arrayWithArray:_photosArray];
    });
    
    return array;
    
}

- (void)addPhoto:(Photo *)photo
{
    if (photo) {
        // add the write operation using your custom queue
        dispatch_barrier_async(self.concurrentPhotoQueue, ^{
            // this block will never run simultaneously with any other block in concurrentPhotoQueue
            [_photosArray addObject:photo];
            
            // post a notification that you've added the image on the main thread (UI)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self postContentAddedNotification];
            });
        });
    }
}

//*****************************************************************************/
#pragma mark - Public Methods
//*****************************************************************************/

- (void)downloadPhotosWithCompletionBlock:(BatchPhotoDownloadingCompletionBlock)completionBlock
{
    __block NSError *error;
    
    for (NSInteger i = 0; i < 3; i++) {
        NSURL *url;
        switch (i) {
            case 0:
                url = [NSURL URLWithString:kOverlyAttachedGirlfriendURLString];
                break;
            case 1:
                url = [NSURL URLWithString:kSuccessKidURLString];
                break;
            case 2:
                url = [NSURL URLWithString:kLotsOfFacesURLString];
                break;
            default:
                break;
        }
    
        Photo *photo = [[Photo alloc] initwithURL:url
                              withCompletionBlock:^(UIImage *image, NSError *_error) {
                                  if (_error) {
                                      error = _error;
                                  }
                              }];
    
        [[PhotoManager sharedManager] addPhoto:photo];
    }
    
    if (completionBlock) {
        completionBlock(error);
    }
}

//*****************************************************************************/
#pragma mark - Private Methods
//*****************************************************************************/

- (void)postContentAddedNotification
{
    static NSNotification *notification = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notification = [NSNotification notificationWithName:kPhotoManagerAddedContentNotification object:nil];
    });
    
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
}

@end
