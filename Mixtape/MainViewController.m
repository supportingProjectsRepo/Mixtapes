//
//  MainViewController.m
//  Mixtape
//
//  Created by orta therox on 29/09/2011.
//  Copyright 2011 http://ortatherox.com. All rights reserved.
//

#import "MainViewController.h"
#import "MixtapeAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>
#import "LayoutController.h"
#import "AudioController.h"
#import "HelpViewController.h"

#define DegreesToRadians(x) (M_PI * x / 180.0)

static const float OROfflineTimerInterval = 2;
static const float OROfflineInfoDelayBeforeFloat = 8;

@interface MainViewController (private)
- (void)playlistsAreOffline;
- (void)getTrackCount;
@end

@implementation MainViewController
@synthesize loadingImage = _loadingImage;

@synthesize canvas = _CACanvasView;
@synthesize flipsidePopoverController = _flipsidePopoverController;
@synthesize layout = _layout, audio = _audio;
@synthesize helpViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistsReady:)  name:@"PlaylistsSet" object:[[UIApplication sharedApplication] delegate]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHelp:)  name:ORHelpNotification object: nil];
    
    _offlineIndicator.hidden = YES;
    _offlineTextLabel.hidden = YES;
    _offlineProgressView.hidden = YES;
    _offlineTextLabel.text = @"Syncing";
}

- (void)showHelp:(NSNotification*)notification {
    helpViewController = nil;
    helpViewController = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    helpViewController.view.alpha = 0;
    [self.view addSubview:helpViewController.view];
    switch ([[[notification userInfo] objectForKey:ORHelpNotification] intValue]) {
        case 0:
            [helpViewController loginHelp:self];
            break;
        case 1:
            [helpViewController folderHelp:self];
            break;
        default:
            [helpViewController recommendHelp:self];
            break;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        helpViewController.view.alpha = 1;        
    }];
}

- (void)playlistsReady:(id)notification {
    [self removeLoadingNotice];
    [self.layout setupAlbumArtwork];
    [self.layout transitionIntoFloorView];
    [self.layout setupGestureReconition];
    
    [[SPSession sharedSession] addObserverForKeyPath:@"offlineTracksRemaining" task:^(id obj, NSDictionary *change) {
        NSInteger tracksRemaining =  [obj offlineTracksRemaining];
        if (tracksRemaining > _totalTracksToDownload) {
            _totalTracksToDownload = tracksRemaining;
        }
        
        _offlineProgressView.progress = (_totalTracksToDownload - tracksRemaining) / _totalTracksToDownload;
        NSLog(@" %d / %i perc remaining", _totalTracksToDownload - tracksRemaining, _totalTracksToDownload); 
    }];


    
    [NSTimer scheduledTimerWithTimeInterval:OROfflineTimerInterval target:self selector:@selector(checkPlaylistsAreOffline:) userInfo:nil repeats:YES];
}

- (void)getTrackCount {
    _totalTracks = [SPSession sharedSession].offlineTracksRemaining;
}

- (void)checkPlaylistsAreOffline:(NSTimer *)timer {
    _offlineIndicator.hidden = NO;
    _offlineTextLabel.hidden = NO;
    
    MixtapeAppDelegate * appDelegate = (MixtapeAppDelegate*)[[UIApplication sharedApplication] delegate];
    for (SPPlaylist * playlist in appDelegate.playlists) {
        if (playlist.markedForOfflinePlayback != YES) {
            playlist.markedForOfflinePlayback = YES;            
        }
        if ([playlist offlineStatus] != SP_PLAYLIST_OFFLINE_STATUS_YES) {
            _offlineProgressView.hidden = NO;
            return;
        }
    }
    [timer invalidate];
    [self playlistsAreOffline];
}

- (void)playlistsAreOffline {
    _offlineIndicator.image = [UIImage imageNamed:@"offline_indicator"];
    _offlineTextLabel.text = @"Offline";
    [self performSelector:@selector(fadeOutOfflineInfo) withObject:self afterDelay:OROfflineInfoDelayBeforeFloat];
}

- (void)fadeOutOfflineInfo {
    [UIView beginAnimations:@"hideOfflineInfo" context:NULL];
    [UIView setAnimationDuration:1.0];
    [_offlineIndicator setAlpha: 0];
    [_offlineTextLabel setAlpha:0];
    [_offlineProgressView setAlpha:0];
    [UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
    [UIView commitAnimations];
}

- (NSMutableArray *)currentPlaylist {
    return [self.layout currentPlaylist];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        return YES;
    }
    return NO;
    
//    // Return YES for supported orientations
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//    } else {
//        
//        if ( UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
//            _background.image = [UIImage imageNamed:@"bg2.jpg"];
//        }else{
//            _background.image = [UIImage imageNamed:@"bg.jpg"];      
//        }
//        
//        return YES;
//    }
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
    }
}

- (IBAction)showInfo:(id)sender
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideViewController" bundle:nil];
        controller.delegate = self;
        controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:controller animated:YES];
    } else {
        if (!self.flipsidePopoverController) {
            FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideViewController" bundle:nil];
            controller.delegate = self;
            
            self.flipsidePopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
        }
        if ([self.flipsidePopoverController isPopoverVisible]) {
            [self.flipsidePopoverController dismissPopoverAnimated:YES];
        } else {
            [self.flipsidePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

-(void) removeLoadingNotice {
    [UIView beginAnimations:@"hideLoading" context:NULL];
    [UIView setAnimationDuration:1.0];
    [self.loadingImage setAlpha: 0];
    [UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
    [UIView commitAnimations];
    
	[self.loadingImage performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
}
@end
