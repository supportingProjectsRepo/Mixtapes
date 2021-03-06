//
//  TrackLayer.h
//  Mixtape
//
//  Created by orta therox on 30/09/2011.
//  Copyright 2011 http://ortatherox.com. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface TrackLayer : CATextLayer {
  int _monitorCount;
  int _shifted;
  SPTrack * _track;
  CALayer * _playButton;
}

@property (retain, nonatomic) SPTrack * track;
@property (retain, nonatomic) CALayer * playButton;

- (id)initWithTrack:(SPTrack*)track;
- (void)turnToThumbnailWithScale:(float)scale;
- (void)turnToSelected;
- (void)turnToUnSelected;
- (void)repositionWithIndex:(int)index inRelationTo: (int)currentlyPlayingIndex;

@end
