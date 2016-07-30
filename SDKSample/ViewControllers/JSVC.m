//
//  JSVC.m
//  SDKSample
//

#import "JSVC.h"
#import "JSDrone.h"
#import "JSVideoView.h"

#import <AVFoundation/AVFoundation.h>

#import "AudioStreamAUBackend.h"
#import "QRScannerService.h"
#import "UIImageProvider.h"

typedef enum {
    AUDIO_STATE_MUTE = 0,
    AUDIO_STATE_INPUT,
    AUDIO_STATE_BIDIRECTIONAL,
} eAUDIO_STATE;

@interface JSVC ()<JSDroneDelegate>

@property (nonatomic, strong) UIAlertView *connectionAlertView;
@property (nonatomic, strong) UIAlertController *downloadAlertController;
@property (nonatomic, strong) UIProgressView *downloadProgressView;
@property (nonatomic, strong) JSDrone *jsDrone;
@property (nonatomic) dispatch_semaphore_t stateSem;

@property (nonatomic, assign) NSUInteger nbMaxDownload;
@property (nonatomic, assign) int currentDownloadIndex; // from 1 to nbMaxDownload
@property (nonatomic, assign) eAUDIO_STATE audioState;

@property (nonatomic) BOOL running;

@property (nonatomic, strong) IBOutlet JSVideoView *videoView;
@property (nonatomic, strong) IBOutlet UILabel *batteryLabel;
@property (nonatomic, strong) IBOutlet UIImageView * commandImageView;

@end

@implementation JSVC

-(void)viewDidLoad {
    _stateSem = dispatch_semaphore_create(0);
    
    _jsDrone = [[JSDrone alloc] initWithService:_service];
    [_jsDrone setDelegate:self];
    [_jsDrone connect];
    
    _connectionAlertView = [[UIAlertView alloc] initWithTitle:[_service name] message:@"Connecting ..."
                                           delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
    _audioState = AUDIO_STATE_MUTE;
}

- (void)viewDidAppear:(BOOL)animated {
    if ([_jsDrone connectionState] != ARCONTROLLER_DEVICE_STATE_RUNNING) {
        [_connectionAlertView show];
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    AudioStreamAUBackend *audioStream = [AudioStreamAUBackend sharedInstance];
    [audioStream stopPlaying];
    [audioStream stopRecording];
    
    if (_connectionAlertView && !_connectionAlertView.isHidden) {
        [_connectionAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    _connectionAlertView = [[UIAlertView alloc] initWithTitle:[_service name] message:@"Disconnecting ..."
                                           delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [_connectionAlertView show];
    
    // in background, disconnect from the drone
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_jsDrone disconnect];
        // wait for the disconnection to appear
        dispatch_semaphore_wait(_stateSem, DISPATCH_TIME_FOREVER);
        _jsDrone = nil;
        
        // dismiss the alert view in main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [_connectionAlertView dismissWithClickedButtonIndex:0 animated:TRUE];
        });
    });
}

#pragma mark JSDroneDelegate
-(void)jsDrone:(JSDrone *)jsDrone connectionDidChange:(eARCONTROLLER_DEVICE_STATE)state {
    switch (state) {
        case ARCONTROLLER_DEVICE_STATE_RUNNING:
            [_connectionAlertView dismissWithClickedButtonIndex:0 animated:TRUE];
            break;
        case ARCONTROLLER_DEVICE_STATE_STOPPED:
            dispatch_semaphore_signal(_stateSem);
            // Go back
            [self.navigationController popViewControllerAnimated:YES];
            break;
        default:
            break;
    }
}

- (void)jsDrone:(JSDrone*)jsDrone batteryDidChange:(int)batteryPercentage {
    [_batteryLabel setText:[NSString stringWithFormat:@"%d%%", batteryPercentage]];
}

- (BOOL)jsDrone:(JSDrone*)jsDrone configureDecoder:(ARCONTROLLER_Stream_Codec_t)codec {
    return [_videoView configureDecoder:codec];
}

- (BOOL)jsDrone:(JSDrone*)jsDrone didReceiveFrame:(ARCONTROLLER_Frame_t*)frame {
    NSData *imgData = [NSData dataWithBytes:frame->data length:frame->used];
    UIImage *image = [UIImage imageWithData:imgData];
    DroneCommand command = [[[QRScannerService alloc] init] scanAction:image];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self handleCommand:command];
        [self handleCommandImageView:command];
    });
    return [_videoView displayFrame:frame];
}

- (void)jsDrone:(JSDrone*)jsDrone audioStateDidChangeWithInput:(BOOL)inputEnabled output:(BOOL)outputEnabled {

    AudioStreamAUBackend *audioStream = [AudioStreamAUBackend sharedInstance];

    [audioStream stopPlaying];

    if (outputEnabled) {
        [audioStream startRecording:self withSampleRate:8000];
    } else {
        [audioStream stopRecording];
    }
}

- (BOOL)jsDrone:(JSDrone*)jsDrone configureAudioDecoder:(ARCONTROLLER_Stream_Codec_t)codec {

    if (codec.type == ARCONTROLLER_STREAM_CODEC_TYPE_PCM16LE) {
        AudioStreamAUBackend *audioStream = [AudioStreamAUBackend sharedInstance];
        [audioStream startPlayingWithSampleRate:codec.parameters.pcm16leParameters.sampleRate];
    }

    return true;
}

- (BOOL)jsDrone:(JSDrone*)jsDrone didReceiveAudioFrame:(ARCONTROLLER_Frame_t*)frame {

    AudioStreamAUBackend *audioStream = [AudioStreamAUBackend sharedInstance];
    [audioStream queueBuffer:frame->data withSize:frame->used];

    return true;
}

- (void)handleCommand:(DroneCommand)command {
    if (!_running && command != Unknown) {
        _running = YES;
        switch (command) {
            case Forward:
                [self doForward];
                _running = NO;
                break;
            case TurnLeft:
                [self doTurnLeft];
                _running = NO;
                break;
            case TurnRight:
                [self doTurnRight];
                _running = NO;
                break;
            case Fire:
                [self doForward];
                [NSThread sleepForTimeInterval:0.5f];
                [self doForward];
                [NSThread sleepForTimeInterval:0.5f];
                [self doForward];
                [NSThread sleepForTimeInterval:0.5f];
                [self doTurnRight];
                [NSThread sleepForTimeInterval:0.5f];
                [self doForward];
                [NSThread sleepForTimeInterval:0.5f];
                [self doForward];
            case Repeat4:
                for (int i = 0; i < 4; i++) {
                    [self doForward];
                }
                _running = NO;
            case Function1:
            default:
                break;
        }
    }
}

- (void)handleCommandImageView:(DroneCommand)command {
    if (command == Unknown) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.commandImageView.image = [UIImageProvider imageForCommand:command];
        self.commandImageView.alpha = 1.0;
        [UIView animateWithDuration:3.0 delay:0.0 options:0 animations:^{
            self.commandImageView.alpha = 0.0f;
        } completion:nil];
    });
}

// Drone Actions

- (void)doForward {
    [_jsDrone setSpeed:25];
    [_jsDrone setFlag:1];
    [NSThread sleepForTimeInterval:1.0f];
    [_jsDrone setSpeed:0];
    [_jsDrone setFlag:0];
}

- (void)doTurnRight {
    [_jsDrone setTurn:50/4.0];
    [_jsDrone setFlag:1];
    [NSThread sleepForTimeInterval:1.0f];
    [_jsDrone setFlag:0];
    [_jsDrone setTurn:0];
}

- (void)doTurnLeft {
    [_jsDrone setTurn:-50/4.0];
    [_jsDrone setFlag:1];
    [NSThread sleepForTimeInterval:1.0f];
    [_jsDrone setFlag:0];
    [_jsDrone setTurn:0];
}

@end
