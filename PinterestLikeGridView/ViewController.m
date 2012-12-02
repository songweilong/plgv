//
//  ViewController.m
//  PinterestLikeGridView
//
//  Created by Weilong Song on 11/23/12.
//  Copyright (c) 2012 Weilong Song. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _plgvView = [[PLGView alloc] initWithConfig:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
                                                 columns:5
                                             columnSpace:10
                                                    data:nil];
    _plgvView.plgvDelegate = self;
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 100)];
    topView.backgroundColor = [UIColor redColor];
    [_plgvView addSubview:topView];
    _plgvView.topPadding = 110;
    [self.view addSubview:_plgvView];
    NSLog(@"w%f, h%f", self.view.frame.size.width, self.view.frame.size.height);
    UIButton *buttonAdd = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [buttonAdd addTarget:self action:@selector(addMoreData) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonAdd];
    
    UIButton *buttonReload = [UIButton buttonWithType:UIButtonTypeContactAdd];
    buttonReload.frame = CGRectMake(0, 30, buttonReload.frame.size.width,buttonReload.frame.size.height);
    [buttonReload addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonReload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return YES;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;

}
-(void)addMoreData{
    NSArray *data = [self getTestData];
    [_plgvView.data addObjectsFromArray:data];
    [_plgvView redrawVisibleScrollView];    
}
-(void)reload{
    _plgvView.data = [NSMutableArray arrayWithArray:[self getTestData]];
    [_plgvView reload];
}
-(NSArray *)getTestData
{
    return @[
    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
//    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
//    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
//    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
//    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
//    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
//    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
//    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
//    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192}
    ];
}

#pragma mark - plgvDelegate
-(PLGViewCell *)plgvView:(PLGView *)plgView cellForRow:(NSInteger)row{
    NSString *identifier = @"cell";
    PLGViewCell *cell = [plgView dequeueReusableCellWithIdentifier:identifier];
    if(cell == nil){
        NSLog(@"new cell in row :%d", row);
        cell = [[PLGViewCell alloc] initWithReuseIdentifier:identifier];
    }else{
        NSLog(@"reuse in row:%d",row);
    }
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:10];
    if(!imageView){
        imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setTag:10];
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell addSubview:imageView];
    }
    imageView.frame = CGRectMake(0, 0, [plgView.data[row][@"w"] floatValue], [plgView.data[row][@"h"] floatValue]);
    imageView.image = [UIImage imageNamed:plgView.data[row][@"img"]];
    return cell;
}
-(CGFloat)plgvView:(PLGView *)plgView heightForCell:(NSInteger)row{
    CGFloat h = [plgView.data[row][@"h"] floatValue];
    return h;
}

@end
