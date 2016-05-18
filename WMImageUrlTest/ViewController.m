//
//  ViewController.m
//  WMImageUrlTest
//
//  Created by wangwendong on 16/5/17.
//  Copyright © 2016年 sunricher. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "DatabaseManager.h"

static NSString *const SegueMainToImage = @"MainToImageListSegue";

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;

@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupMainImageView];
    
    [self setupImagePickerController];
}

- (IBAction)photoClicked:(id)sender {
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}

- (IBAction)cameraClicked:(id)sender {
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}

- (IBAction)listClicked:(id)sender {
    [self performSegueWithIdentifier:SegueMainToImage sender:self];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString *typeString = [info valueForKey:UIImagePickerControllerMediaType];
    
    if ([typeString isEqualToString:(NSString *)kUTTypeImage]) {
//        UIImage *originImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        UIImage *editedImage = [info objectForKey:UIImagePickerControllerEditedImage];
        
        if (editedImage) {
            _mainImageView.image = editedImage;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
                [[DatabaseManager sharedDatabaseManager] insertImage:editedImage];
            });
            
            [picker dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - Private

- (void)setupMainImageView {
    _mainImageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)setupImagePickerController {
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.allowsEditing = YES;
    
    
    _imagePickerController.delegate = self;
}

@end
