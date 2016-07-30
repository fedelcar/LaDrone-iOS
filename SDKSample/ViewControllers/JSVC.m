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

@property (nonatomic, strong) IBOutlet JSVideoView *videoView;
@property (nonatomic, strong) IBOutlet UILabel *batteryLabel;

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
        if (command == Forward) {
            [self forwardTouchDown:nil];
            [NSThread sleepForTimeInterval:1.0f];
            [self forwardTouchUp:nil];
        } else if (command == Backward) {
            [self backwardTouchDown:nil];
            [NSThread sleepForTimeInterval:1.0f];
            [self backwardTouchUp:nil];
        } else if (command == TurnLeft) {
            [self turnLeftTouchDown:nil];
            [NSThread sleepForTimeInterval:1.0f];
            [self turnLeftTouchUp:nil];
        } else if (command == TurnRight) {
            [self turnRightTouchDown:nil];
            [NSThread sleepForTimeInterval:1.0f];
            [self turnRightTouchUp:nil];
        }
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

#pragma mark buttons click

- (IBAction)takePictureClicked:(id)sender {
    [_jsDrone takePicture];
}

- (IBAction)turnLeftTouchDown:(id)sender {
    [_jsDrone setFlag:1];
    [_jsDrone setTurn:-50];
}

- (IBAction)turnRightTouchDown:(id)sender {
    [_jsDrone setFlag:1];
    [_jsDrone setTurn:50];
}

- (IBAction)turnLeftTouchUp:(id)sender {
    [_jsDrone setFlag:0];
    [_jsDrone setTurn:0];
}

- (IBAction)turnRightTouchUp:(id)sender {
    [_jsDrone setFlag:0];
    [_jsDrone setTurn:0];
}

- (IBAction)forwardTouchDown:(id)sender {
    [_jsDrone setFlag:1];
    [_jsDrone setSpeed:50];
}

- (IBAction)backwardTouchDown:(id)sender {
    [_jsDrone setFlag:1];
    [_jsDrone setSpeed:-50];
}

- (IBAction)forwardTouchUp:(id)sender {
    [_jsDrone setFlag:0];
    [_jsDrone setSpeed:0];
}

- (IBAction)backwardTouchUp:(id)sender {
    [_jsDrone setFlag:0];
    [_jsDrone setSpeed:0];
}

@end
