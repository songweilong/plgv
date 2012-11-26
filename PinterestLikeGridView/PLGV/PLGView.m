//
//  PLGView.m
//  PinterestLikeGridView
//
//  Created by Weilong Song on 11/23/12.
//  Copyright (c) 2012 Weilong Song. All rights reserved.
//

#import "PLGView.h"

#define THRESHOLD_SPEED    1.0f   //THRESHOLD_SPEED是一个速度阀值, 如果scrollView滚动的速度低于它
                                  //则认为是慢速滚动, 人眼可以识别滚动的内容,我们就要向瀑布流中画入cells
                                  //这个值没有特定参考, 是实测出的一个较为合理的数据, 可以自行测试修改
#define PRELOAD_HEIGHT     (self.frame.size.height/3)  //瀑布流高度的三分之一作为预读数据的高度

@implementation PLGView

-(id)initWithConfig:(CGRect)frame            //瀑布流区域的大小
             columns:(NSInteger)columns      //列数
         columnSpace:(NSInteger)columnSpace  //每列之间的平均间距
                data:(NSArray *)data         //内容数据
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.delegate = self;
        self.backgroundColor = [UIColor grayColor];
        self.columns = columns;
        self.columnSpace = columnSpace;
        self.columnWidthF = (frame.size.width - (self.columns + 1) * self.columnSpace) / self.columns;
        self.columnWidth = self.columnWidthF;
        NSLog(@"每列的float宽度为%f", self.columnWidthF);
        NSLog(@"每列的int宽度为%i", self.columnWidth);
        self.scrollViewHeight = self.frameHeight + 1; // +1 是为了让它可以上下拖动,bounced
        self.data = data;
        self.columnX = [NSMutableArray arrayWithCapacity:self.columns];
        /*
         columnY说明
         @{
            @"1": @{                   //第一列
                @"upAdd"  : @100.0f,   //最下面一个cell的y+h, 即将跟整个瀑布流的y+h对比, <= 则add cell
                @"upDel"  : @100.0f,   //最上面一个cell的y+h, 即将跟整个瀑布流的y  对比, <= 则del cell
                @"downAdd": @100.0f,   //最上面一个cell的y,   即将跟整个瀑布流的y  对比, >= 则add cell
                @"downDel": @100.0f    //最下面一个cell的y,   即将跟整个瀑布流的y+h对比, >= 则del cell
            },
            @"2": @{                   //第二列
                @"upAdd"  : @100.0f,
                @"upDel"  : @100.0f,
                @"downAdd": @100.0f,
                @"downDel": @100.0f
            }
            ...
         }
         */
        self.columnY = [NSMutableDictionary dictionaryWithCapacity:self.columns];
        self.cellsPool = [NSMutableSet set];
        self.visibleCellsPool = [NSMutableSet set];
        //初始化columnX 初始化columnY 初始化Cells池
        [self initProperties];
        self.frameWidth = frame.size.width;
        self.frameHeight = frame.size.height;
        self.currentOffsetY = 0;
        self.superscriptOfData = 0;
        self.subscriptOfData = 0;
        self.isScrollingSlow = YES;
        self.workingInProgress = NO;
        
        self.contentSize = CGSizeMake(self.frameWidth,
                                      self.scrollViewHeight);
        //测试数据 TODO: to be deleted
        self.data = [self getTestData];
    }
    return self;
}

//初始化columnX 初始化columnY 初始化Cells池
-(void)initProperties
{
    float widthThatWeIgnored = (self.columnWidthF - self.columnWidth) * self.columns;
    NSInteger theFirstLeftSapce = (widthThatWeIgnored / 2) + self.columnSpace;
    for (NSInteger i = 0; i < self.columns; i++) {
        //初始化columnX
        self.columnX[i] = [NSNumber numberWithInt:theFirstLeftSapce + (self.columnWidth + self.columnSpace) * i];
        NSLog(@"第%d列的X坐标为%d", (i+1), [self.columnX[i] intValue]);
        
        //初始化columnY
        self.columnY[@(i)] = [@{
        @"upAdd"  : @0.0f,
//        @"upDel"  : @0.0f,
        @"downAdd": @0.0f,
//        @"downDel": @0.0f
        } mutableCopy];
        
        //初始化Cells池
        [self addCellInToCellsPoll];
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
-(void)drawRect:(CGRect)rect
{
    // Drawing code
    // 读取data中的数据并加到scrollview中去
    [self initContent];
    NSLog(@"初始化后总共添加了%d个Cells", [self.subviews count]);
    
}

//初始化给瀑布流加入内容
-(void)initContent
{
    NSInteger i = 0;
    NSInteger lowestColumnHeight = 0;
    while (lowestColumnHeight < self.frameHeight) {
        NSLog(@"正在添加第%d个Cell, 现在最低的columnHeight为%d", i, lowestColumnHeight);
        NSDictionary *o = self.data[i];
        //调用画cell的方法
        [self renderCells:@"up" data:o];
        lowestColumnHeight = [self getTheLowestHeightForAddingCell];
        i++;
    }
    NSLog(@"初始化完毕: dataOffset:[%d, %d]", self.superscriptOfData, self.subscriptOfData);
}

//在内存中创建一个cell并且增加到cells池中
-(void)addCellInToCellsPoll
{
    UIView *cell = [[UIView alloc] init];
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setTag:10];
    [cell setBackgroundColor:[UIColor whiteColor]];
    [cell addSubview:imageView];
    [self.cellsPool addObject:cell];
}

//scrollView正在滚动的过程中调用的方法
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.currentOffsetY = scrollView.contentOffset.y;
    //滚动的过程中实时监控滚动速度
    CGPoint currentOffset = self.contentOffset;
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval timeDiff = currentTime - self.lastOffsetCapture;
    //如果本次获取offset的时间比上次时间大0.1秒
    if(timeDiff > 0.1) {
        //0.1秒滚动距离差distance
        CGFloat distance = currentOffset.y - self.lastOffset.y;
        //计算速度
        CGFloat scrollSpeedF = distance / 100; // 100ms = 0.1s
        CGFloat scrollSpeed = fabsf(scrollSpeedF);
        //NSLog(@"=======================%f", currentTime);
        if (scrollSpeed > THRESHOLD_SPEED) {
            //self.isScrollingSlow = NO;
            //NSLog(@"=============>快速滚动");
        } else {
            self.isScrollingSlow = YES;
            //NSLog(@"<===慢速滚动");
        }
        self.lastOffset = currentOffset;
        self.lastOffsetCapture = currentTime;
    }
    if (self.currentOffsetY > self.offsetWillBeginDragging.y) {
        //如果是向上滚动
        [self handleCells:@"up"];
    } else if (self.currentOffsetY < self.offsetWillBeginDragging.y) {
        //如果是向下滚动
        [self handleCells:@"down"];
    }
}

//计算目前是向上滚动还是向下滚动用的
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.offsetWillBeginDragging = scrollView.contentOffset;
}

//处理将要增加和删除的cells
-(void)handleCells:(NSString *)direction
{
    if (self.workingInProgress) {
        return;
    }
    self.cellsToBeRemoved = [@[] mutableCopy];
    if ([@"up" isEqualToString:direction]) {
        NSInteger bottomLowestHeight = [self getTheLowestHeightForAddingCell];
        //render cell
        if (bottomLowestHeight - PRELOAD_HEIGHT <= self.currentOffsetY + self.frameHeight) {
            if (self.subscriptOfData + 1 <= [self.data count] - 1) {
                [self renderCells:direction data:self.data[self.subscriptOfData + 1]];
            }
        }
        NSEnumerator *enumerator = [self.visibleCellsPool objectEnumerator];
        UIView *cell;
        while (cell = [enumerator nextObject])
        {
            //recycle cell
            if (cell.frame.origin.y + cell.frame.size.height < self.currentOffsetY) {
                [self.cellsToBeRemoved addObject:cell];
            }
        }
        [self.cellsToBeRemoved enumerateObjectsUsingBlock:^(UIView *cell, NSUInteger idx, BOOL *stop) {
            [self recycleCells:direction cell:cell];
        }];
    }
    
    if([@"down" isEqualToString:direction]) {
        NSInteger topHighestHeight = [self getTheHighestHeightForAddingCell];
        //render cell
        if (topHighestHeight + PRELOAD_HEIGHT >= self.currentOffsetY && self.currentOffsetY >= 0) {
            if (self.superscriptOfData - 1 >= 0) {
                [self renderCells:direction data:self.data[self.superscriptOfData - 1]];
            }
        }
        NSEnumerator *enumerator = [self.visibleCellsPool objectEnumerator];
        UIView *cell;
        while (cell = [enumerator nextObject])
        {
            //recycle cell
            if (cell.frame.origin.y > self.currentOffsetY + self.frameHeight) {
                [self.cellsToBeRemoved addObject:cell];
            }
        }
        [self.cellsToBeRemoved enumerateObjectsUsingBlock:^(UIView *cell, NSUInteger idx, BOOL *stop) {
            [self recycleCells:direction cell:cell];
        }];
    }
    
}

//回收cells
-(void)recycleCells:(NSString *)direction cell:(UIView *)cell
{
    //return;
    NSInteger columnNumber = [self getColumnNumberByX:cell.frame.origin.x];
    [self.cellsPool addObject:cell];
    [cell removeFromSuperview];
    [self.visibleCellsPool removeObject:cell];
    NSLog(@"[<==销毁了一个Cell]");
    
    if([@"up" isEqualToString:direction]) {
        //更新columnY
        self.columnY[@(columnNumber)][@"downAdd"] = [NSNumber numberWithInt:([self.columnY[@(columnNumber)][@"downAdd"] intValue] + cell.frame.size.height + self.columnSpace)];
        self.superscriptOfData++;
    }
    
    if([@"down" isEqualToString:direction]) {
        //更新columnY
        self.columnY[@(columnNumber)][@"upAdd"] = [NSNumber numberWithInt:([self.columnY[@(columnNumber)][@"upAdd"] intValue] - cell.frame.size.height - self.columnSpace)];
        self.subscriptOfData--;
    }
    NSLog(@"销毁一个Cell: dataOffset:[%d, %d]", self.superscriptOfData, self.subscriptOfData);
}

//向瀑布流添加cells
-(void)renderCells:(NSString *)direction data:(NSDictionary *)data
{
    self.workingInProgress = YES;
//    NSLog(@"%@", data[@"img"]);

    //计算下一个cell要加入到哪个位置
    CGPoint origin = [self getOrigin:direction];
    
    //看看cells池中是否还有可用的cell,如果没有就创建一个放进去
    NSInteger cellsPollSize = [self.cellsPool count];
    if (cellsPollSize <= 0) {
        //如果cellsPoll里面已经没有cell了,就创建一个并加进去
        [self addCellInToCellsPoll];
    }
    
    //获取现在操作的是哪一列
    NSInteger columnNumber = [self getColumnNumberByX:origin.x];
    
    UIView *cell = [self.cellsPool anyObject];
    UIImageView *imageView;
    if ([@"up" isEqualToString:direction]) {
        [cell setFrame:CGRectMake(origin.x, origin.y, self.columnWidth, [data[@"h"] floatValue])];
        imageView = (UIImageView *)[cell viewWithTag:10];
        cell.backgroundColor = [UIColor redColor];
        if (self.isScrollingSlow) {
            NSLog(@"插入图片%@", data[@"img"]);
            NSLog(@"columnWidth: %d", self.columnWidth);
            NSLog(@"data-h: %@", data[@"h"]);
            imageView.frame = CGRectMake(0, 0, self.columnWidth, [data[@"h"] floatValue]);
            imageView.image = [UIImage imageNamed:data[@"img"]];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
        [self addSubview:cell];
        [self.visibleCellsPool addObject:cell];
        NSLog(@"[==>下面增加了一个Cell]");
        //更新data指针
        self.subscriptOfData++;
        //更新columnY
        self.columnY[@(columnNumber)][@"upAdd"] = [NSNumber numberWithInt:([self.columnY[@(columnNumber)][@"upAdd"] intValue] + [data[@"h"] intValue] + self.columnSpace)];
    }
    if ([@"down" isEqualToString:direction]) {
        [cell setFrame:CGRectMake(origin.x, (origin.y - self.columnSpace - [data[@"h"] intValue]), self.columnWidth, [data[@"h"] floatValue])];
        imageView = (UIImageView *)[cell viewWithTag:10];
        if (self.isScrollingSlow) {
            NSLog(@"插入图片%@", data[@"img"]);
            imageView.frame = CGRectMake(0, 0, self.columnWidth, [data[@"h"] floatValue]);
            imageView.image = [UIImage imageNamed:data[@"img"]];
        }
        [self addSubview:cell];
        [self.visibleCellsPool addObject:cell];
        NSLog(@"[==>上面增加了一个Cell]");
        //更新data指针
        self.superscriptOfData--;
        //更新columnY
        self.columnY[@(columnNumber)][@"downAdd"] = [NSNumber numberWithInt:([self.columnY[@(columnNumber)][@"downAdd"] intValue] - [data[@"h"] intValue] - self.columnSpace)];
    }
    
    //移除cellsPoll中的这个UIView
    [self.cellsPool removeObject:cell];
    
    //更新瀑布流的总高度
    if (origin.y + [data[@"h"] floatValue] > self.scrollViewHeight) {
        self.scrollViewHeight = origin.y + [data[@"h"] floatValue];
        //图片画完后把contentSize改成最高那一列的高度. 如果画完还比初始化的小, 那就不改了.
        self.contentSize = CGSizeMake(self.frameWidth, self.scrollViewHeight);
    }
    
    self.workingInProgress = NO;
    NSLog(@"增加一个Cell: dataOffset:[%d, %d]", self.superscriptOfData, self.subscriptOfData);
    
    //test
//    for (UIView *v in [self subviews]) {
//        NSLog(@"CellY is %f", v.frame.origin.y);
//    }
    NSLog(@"||||||||");
    NSLog(@"=============================");
    NSLog(@"= [%@, %@, %@, %@, %@]", self.columnY[@0][@"upAdd"], self.columnY[@1][@"upAdd"], self.columnY[@2][@"upAdd"], self.columnY[@3][@"upAdd"], self.columnY[@4][@"upAdd"]);
//    NSLog(@"= [%f]", origin.x);
//    NSLog(@"= (%d)+%f", columnNumber+1, origin.y);
    NSLog(@"= cell: %@", NSStringFromCGRect(cell.frame));
    NSLog(@"= cell: %@", [cell description]);
    NSLog(@"= imageView: %@", NSStringFromCGRect(imageView.frame));
    NSLog(@"=============================");
}

-(CGPoint)getOrigin:(NSString *)direction
{
    NSInteger x = self.columnSpace;
    id y;
    if ([@"up" isEqualToString:direction]) {
        y = self.columnY[@0][@"upAdd"];
        for (NSInteger i = 1; i < self.columns; i++) {
//            NSLog(@"第%d列的高度为%@, Y为%@", i, self.columnY[@(i)][@"upAdd"], y);
            if ([self.columnY[@(i)][@"upAdd"] floatValue] - PRELOAD_HEIGHT < [y floatValue]) {
                y = self.columnY[@(i)][@"upAdd"];
                x = i * (self.columnWidth + self.columnSpace) + self.columnSpace;
            }
        }
    }
    if ([@"down" isEqualToString:direction]) {
        y = self.columnY[@0][@"downAdd"];
        for (NSInteger i = 1; i < self.columns; i++) {
            if ([self.columnY[@(i)][@"downAdd"] floatValue] + PRELOAD_HEIGHT > [y floatValue]) {
                y = self.columnY[@(i)][@"downAdd"];
                x = i * (self.columnWidth + self.columnSpace) + self.columnSpace;
            }
        }
    }
    
//    NSLog(@"下一个Cell的origin为%d, %@", x, y);    
    return CGPointMake(x, [y floatValue]);
}

-(NSInteger)getColumnNumberByX:(float)x
{
    return (x - self.columnSpace) / (self.columnSpace + self.columnWidth);
}


-(NSInteger)getTheLowestHeightForAddingCell
{
    id y = self.columnY[@0][@"upAdd"];
    for (NSInteger i = 1; i < self.columns; i++) {
        if ([self.columnY[@(i)][@"upAdd"] floatValue] < [y floatValue]) {
            y = self.columnY[@(i)][@"upAdd"];
        }
    }
    return [y intValue];
}


-(NSInteger)getTheHighestHeightForAddingCell
{
    id y = self.columnY[@0][@"downAdd"];
    for (NSInteger i = 1; i < self.columns; i++) {
        if ([self.columnY[@(i)][@"downAdd"] floatValue] > [y floatValue]) {
            y = self.columnY[@(i)][@"downAdd"];
        }
    }
    return [y intValue];
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
    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192},
    @{@"img": @"a1.jpeg", @"h": @242,  @"w": @192},
    @{@"img": @"a2.jpeg", @"h": @127,  @"w": @192},
    @{@"img": @"a3.jpeg", @"h": @239,  @"w": @192},
    @{@"img": @"a4.jpeg", @"h": @572,  @"w": @192},
    @{@"img": @"a5.jpeg", @"h": @72,   @"w": @192},
    @{@"img": @"a6.jpeg", @"h": @1221, @"w": @192},
    @{@"img": @"a7.jpeg", @"h": @259,  @"w": @192},
    @{@"img": @"a8.jpeg", @"h": @440,  @"w": @192}
    ];
}

@end