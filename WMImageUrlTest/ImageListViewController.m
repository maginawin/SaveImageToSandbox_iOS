//
//  ImageListViewController.m
//  WMImageUrlTest
//
//  Created by wangwendong on 16/5/17.
//  Copyright © 2016年 sunricher. All rights reserved.
//

#import "ImageListViewController.h"
#import "DatabaseManager.h"

@interface ImageListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *imageListTableView;

@property (strong, nonatomic) NSMutableArray *imageListMutableArray;

@property (strong, nonatomic) NSMutableArray *imagesMutableArray;

@end

@implementation ImageListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupImageListMutalbeArray];
    
    [self setupImagesMutableArray];
    
    [self setupImageListTableView];
}

- (IBAction)editClicked:(id)sender {
    if (_imageListTableView.isEditing) {
        [_imageListTableView setEditing:NO animated:YES];
        
        return;
    }
    
    [_imageListTableView setEditing:YES animated:YES];
}

- (IBAction)closeClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > 0 && _imagesMutableArray.count > 1) {
        UIImage *image = _imagesMutableArray.firstObject;
        NSString *imageUrl = _imageListMutableArray[indexPath.row];
        
        if (image && imageUrl) {
            [[DatabaseManager sharedDatabaseManager] updateImage:image imageUrl:imageUrl];
            
            [_imagesMutableArray replaceObjectAtIndex:indexPath.row withObject:image];
            
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *imageUrl = _imageListMutableArray[indexPath.row];
        
        [[DatabaseManager sharedDatabaseManager] deleteImageByImageUrl:imageUrl];
        
        [_imageListMutableArray removeObjectAtIndex:indexPath.row];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _imageListMutableArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *imageListTableViewCellIdentifier = @"imageListTableViewCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:imageListTableViewCellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageListTableViewCellIdentifier];
    }
    
    NSString *imageUrl = _imageListMutableArray[indexPath.row];
    
    cell.textLabel.text = imageUrl;
    
    if (_imagesMutableArray.count > indexPath.row) {
        UIImage *image = _imagesMutableArray[indexPath.row];
        if (image) {
            cell.imageView.image = image;
        }
    }
    
    return cell;
}

#pragma mark - Setup

- (void)setupImageListMutalbeArray {
    if (!_imageListMutableArray) {
        _imageListMutableArray = [NSMutableArray array];
    }
    
    [_imageListMutableArray removeAllObjects];
    
    NSArray *imagesUrlArray = [[DatabaseManager sharedDatabaseManager] imagesArrayWithType:DatabaseSelectTypeImageUrl];
    
    [_imageListMutableArray addObjectsFromArray:imagesUrlArray];
}

- (void)setupImagesMutableArray {
    NSArray *imagesArray = [[DatabaseManager sharedDatabaseManager] imagesArrayWithType:DatabaseSelectTypeImage];
    if (!imagesArray) {
        _imagesMutableArray = [NSMutableArray array];
    }
    _imagesMutableArray = [NSMutableArray arrayWithArray:imagesArray];
}

- (void)setupImageListTableView {

    _imageListTableView.delegate = self;
    _imageListTableView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
