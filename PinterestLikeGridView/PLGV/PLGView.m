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
#define PRELOAD_HEIGHT     (self.frame.size.height/2)  //瀑布流高度的三分之一作为预读数据的高度
#define TOP_PADDING        10.0f

@implementation PLGView

-(id)initWithConfig:(CGRect)frame            //瀑布流区域的大小
             columns:(NSInteger)columns      //列数
         columnSpace:(NSInteger)columnSpace  //每列之间的平均间距
                data:(NSArray *)data         //内容数据
{
    self = [super initWithFrame:frame];
    if (self) {
        //初始化参数
        self.delegate            = self;
        self.backgroundColor     = [UIColor greenColor];
        self.columns             = columns;
        self.columnSpace         = columnSpace;
        self.columnWidthF        = (frame.size.width - (self.columns + 1) * self.columnSpace) / self.columns;
        self.columnWidth         = self.columnWidthF;
        self.cellWidth           = self.columnWidth;
        self.data                = [NSMutableArray arrayWithArray:data];
        self.columnX             = [NSMutableArray arrayWithCapacity:self.columns];
        self.columnVisible       = [NSMutableArray arrayWithCapacity:self.columns];
        self.matrix              = [NSMutableArray arrayWithCapacity:self.columns];
        self.cellsPool           = [NSMutableSet set];
        self.cellsPools          = [NSMutableDictionary dictionary];
        self.frameWidth          = frame.size.width;
        self.frameHeight         = frame.size.height;
        self.isScrollingSlow     = YES;
        self.workingInProgress   = NO;
        self.lastScrollDirection = @"up";
        self.topPadding          = TOP_PADDING;
        
        [self initProperties];
        self.contentSize = CGSizeMake(self.frameWidth, self.scrollViewHeight);
        //测试数据 TODO: to be deleted
    }
    return self;
}

//初始化一些数组和字典
-(void)initProperties
{
    float widthThatWeIgnored = (self.columnWidthF - self.columnWidth) * self.columns;
    NSInteger theFirstLeftSapce = (widthThatWeIgnored / 2) + self.columnSpace;
    for (NSInteger i = 0; i < self.columns; i++) {
        //初始化columnX
        self.columnX[i] = [NSNumber numberWithInt:theFirstLeftSapce + (self.columnWidth + self.columnSpace) * i];
        NSLog(@"第%d列的X坐标为%d", (i+1), [self.columnX[i] intValue]);
        
        //初始化matrix
        self.matrix[i] = [@[] mutableCopy];
//        //初始化Cells池
//        [self addCellInToCellsPoll];
    }
    self.countOfMatrix = 0;
    self.currentOffsetY = 0;
    self.visibleCellsPool = [NSMutableSet set];
    self.scrollViewHeight = self.frameHeight + 1;
    [self initColumnVisible];
}
- (void)setTopPadding:(CGFloat)topPadding{
    _topPadding = topPadding;
    [self initColumnVisible];
}
-(void) initColumnVisible{
    for (NSInteger i = 0; i < self.columns; i++) {

        //初始化columnVisible
        self.columnVisible[i] = [@{
            @"top"    : [@{@"y" : @(self.topPadding ), @"indexInMatrix" : @0} mutableCopy],
            @"bottom" : [@{@"y" : @(self.topPadding ), @"indexInMatrix" : @0} mutableCopy]
        } mutableCopy];
        
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
        if (i >= [self.data count]) {
            break;
        }
        //调用画cell的方法
        [self renderCell:@"up"];
        lowestColumnHeight = [self getTheLowestHeightForAddingCell];
        i++;
    }
    NSLog(@"初始化完毕: columnVisible:%@", self.columnVisible);
//    NSLog(@"初始化完毕: matrix:%@", self.matrix);
}

//在内存中创建一个cell并且增加到cells池中
//-(void)addCellInToCellsPoll
//{
//    PLGViewCell *cell = [[PLGViewCell alloc] init];
//    cell.backgroundColor = [UIColor clearColor];
////    UIImageView *imageView = [[UIImageView alloc] init];
////    [imageView setTag:10];
////    [cell setBackgroundColor:[UIColor whiteColor]];
////    [cell addSubview:imageView];
//    [self.cellsPool addObject:cell];
//}

//scrollView正在滚动的过程中调用的方法
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSLog(@"===============scrollView didScroll!");
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
            self.isScrollingSlow = NO;
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
        [self render:@"up"];
        [self recycle:@"up"];
        self.lastScrollDirection = @"up";
    } else if (self.currentOffsetY < self.offsetWillBeginDragging.y) {
        //如果是向下滚动
        [self render:@"down"];
        [self recycle:@"down"];
        self.lastScrollDirection = @"down";
    }
}

//计算目前是向上滚动还是向下滚动用的
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.offsetWillBeginDragging = scrollView.contentOffset;
}

//处理将要增加和删除的cells
-(void)render:(NSString *)direction
{
    if (self.workingInProgress) {
        return;
    }
    self.cellsToBeRemoved = [@[] mutableCopy];
    if ([@"up" isEqualToString:direction]) {
        NSInteger bottomLowestHeight = [self getTheLowestHeightForAddingCell];
        //render cell
        if (bottomLowestHeight - PRELOAD_HEIGHT <= self.currentOffsetY + self.frameHeight) {
            [self renderCell:direction];
        }
    }
    
    if([@"down" isEqualToString:direction]) {
        NSInteger topHighestHeight = [self getTheHighestHeightForAddingCell];
        //render cell
        if (topHighestHeight + PRELOAD_HEIGHT >= self.currentOffsetY) {
            [self renderCell:direction];
        }
    }
    
}

//删除cells
-(void)recycle:(NSString *)direction
{
    self.cellsToBeRemoved = [@[] mutableCopy];
    if ([@"up" isEqualToString:direction]) {
        NSEnumerator *enumerator = [self.visibleCellsPool objectEnumerator];
        PLGViewCell *cell;
        while (cell = [enumerator nextObject])
        {
            //recycle cell
            if (cell.frame.origin.y + cell.frame.size.height + PRELOAD_HEIGHT < self.currentOffsetY) {
                [self.cellsToBeRemoved addObject:cell];
            }
        }
        [self.cellsToBeRemoved enumerateObjectsUsingBlock:^(PLGViewCell *cell, NSUInteger idx, BOOL *stop) {
//            NSLog(@"--------------%d", [self.cellsToBeRemoved count]);
            [self recycleCells:direction cell:cell];
        }];
    }
    
    if([@"down" isEqualToString:direction]) {
        NSEnumerator *enumerator = [self.visibleCellsPool objectEnumerator];
        PLGViewCell *cell;
        while (cell = [enumerator nextObject])
        {
            //recycle cell
            if (cell.frame.origin.y - PRELOAD_HEIGHT > self.currentOffsetY + self.frameHeight) {
                [self.cellsToBeRemoved addObject:cell];
            }
        }
        [self.cellsToBeRemoved enumerateObjectsUsingBlock:^(PLGViewCell *cell, NSUInteger idx, BOOL *stop) {
//            NSLog(@"--------------%d", [self.cellsToBeRemoved count]);
            [self recycleCells:direction cell:cell];
        }];
    }
    
}


//回收cells
-(void)recycleCells:(NSString *)direction cell:(PLGViewCell *)cell
{
//    NSLog(@"------------------------------------------------------------->");
    NSInteger column = [self getColumnNumberByX:cell.frame.origin.x];
    NSDictionary *cv = self.columnVisible[column];
    //获取cell在瀑布流矩阵数组中的index值
    NSInteger indexInMatrix = [self getIndexInMatrix:column originY:cell.frame.origin.y];
//    NSLog(@"indexInMatrix is : %d", indexInMatrix);
//    [self.cellsPool addObject:cell];
    
    NSMutableSet *set = [self getPoolSet:cell.reuseIdentifier];
    [set addObject:cell];
    
    [cell removeFromSuperview];
    [self.visibleCellsPool removeObject:cell];
//    NSLog(@"recycleCells poolcount :%d", set.count);
    if([@"up" isEqualToString:direction]) {
        if (cell.frame.origin.y >= [cv[@"top"][@"y"] floatValue]) {
            cv[@"top"][@"y"] = @(cell.frame.origin.y + cell.frame.size.height + self.columnSpace);
            cv[@"top"][@"indexInMatrix"] = @(indexInMatrix + 1);
        }
    }
    
    if([@"down" isEqualToString:direction]) {
        if (cell.frame.origin.y <= [cv[@"bottom"][@"y"] floatValue]) {
            cv[@"bottom"][@"y"] = @(cell.frame.origin.y);
            cv[@"bottom"][@"indexInMatrix"] = @(indexInMatrix - 1);
        }
    }
//    NSLog(@"[%@, %@, %@]", self.columnVisible[0][@"top"][@"y"], self.columnVisible[1][@"top"][@"y"], self.columnVisible[2][@"top"][@"y"]);
//    NSLog(@"[%@, %@, %@]", self.columnVisible[0][@"bottom"][@"y"], self.columnVisible[1][@"bottom"][@"y"], self.columnVisible[2][@"bottom"][@"y"]);
//    NSLog(@"[%@, %@, %@]", self.columnVisible[0][@"top"][@"indexInMatrix"], self.columnVisible[1][@"top"][@"indexInMatrix"], self.columnVisible[2][@"top"][@"indexInMatrix"]);
//    NSLog(@"[%@, %@, %@]", self.columnVisible[0][@"bottom"][@"indexInMatrix"], self.columnVisible[1][@"bottom"][@"indexInMatrix"], self.columnVisible[2][@"bottom"][@"indexInMatrix"]);
//    NSLog(@"I am scrolling %@", self.lastScrollDirection);
//    NSLog(@"Deleting image with height %f", cell.frame.size.height);
//    NSLog(@"%@", self.matrix[column]);
//    NSLog(@" ");
}

//向瀑布流添加Cells
-(BOOL)renderCell:(NSString *)direction
{
    self.workingInProgress = YES;
    //计算下一个cell的origin
    CGPoint origin = [self getOrigin:direction];
    NSLog(@"--->%f", origin.y);
    NSLog(@"%@", direction);
    if ([@"down" isEqualToString:direction] && origin.y <= self.topPadding ) {
        self.workingInProgress = NO;
        return NO; //处在最顶端并向下拖动的就不用再向上画内容了
    }
    NSLog(@"--------------->%f", origin.y);
    NSLog(@"%@", direction);
    //计算要加入哪个column
    NSInteger column = [self getColumnNumberByX:origin.x];
    //计算用哪个data来做cell的内容
    NSInteger i = [self getIndexInData:column originY:origin.y direction:direction];
    if (i < 0) {
        self.workingInProgress = NO;
        return NO; //i<0说明没有得到数据的index, 说明已经到了数据末端
    }
//    NSDictionary *o = self.data[i];
    CGFloat h = [self.plgvDelegate plgvView:self heightForCell:i];
    if (i >= self.countOfMatrix) {
        //新增的数据增加到matrix中
        [self.matrix[column] addObject:@{
         @"y" : @(origin.y),
         @"h" : @(h),
         @"indexInData" : @(i)
         }];
        self.countOfMatrix++;
    }
    
    //获取cell在瀑布流矩阵数组中的index值
    NSInteger indexInMatrix = [self getIndexInMatrix:column originY:origin.y];
    
    //看看cells池中是否还有可用的cell,如果没有就创建一个放进去
//    NSInteger cellsPollSize = [self.cellsPool count];
//    if (cellsPollSize <= 0) {
//        [self addCellInToCellsPoll];
//    }
    PLGViewCell *cell = [self.plgvDelegate plgvView:self cellForRow:i];
//    UIView *cell = [self.cellsPool anyObject];
//    UIImageView *imageView;
    if ([@"up" isEqualToString:direction]) {
        [cell setFrame:CGRectMake(origin.x, origin.y, self.columnWidth, h)];
//        imageView = (UIImageView *)[cell viewWithTag:10];
//        cell.backgroundColor = [UIColor redColor];
////        if (self.isScrollingSlow) {
//            imageView.frame = CGRectMake(0, 0, self.columnWidth, [o[@"h"] floatValue]);
//            imageView.image = [UIImage imageNamed:o[@"img"]];
//            imageView.contentMode = UIViewContentModeScaleAspectFit;
////        }
        [self addSubview:cell];
        [self.visibleCellsPool addObject:cell];
        //更新当前可见区域的数组
        self.columnVisible[column][@"bottom"][@"y"] = @(origin.y + h + self.columnSpace);
        self.columnVisible[column][@"bottom"][@"indexInMatrix"] = @(indexInMatrix);
    }
    if ([@"down" isEqualToString:direction]) {
        [cell setFrame:CGRectMake(origin.x, (origin.y - self.columnSpace - h), self.columnWidth, h)];
//        imageView = (UIImageView *)[cell viewWithTag:10];
////        if (self.isScrollingSlow) {
//            imageView.frame = CGRectMake(0, 0, self.columnWidth, [o[@"h"] floatValue]);
//            imageView.image = [UIImage imageNamed:o[@"img"]];
//            imageView.contentMode = UIViewContentModeScaleAspectFit;
////        }
        [self addSubview:cell];
        [self.visibleCellsPool addObject:cell];
        //更新当前可见区域的数组
        self.columnVisible[column][@"top"][@"y"] = @(origin.y - h - self.columnSpace);
        self.columnVisible[column][@"top"][@"indexInMatrix"] = @(indexInMatrix - 1);
    }
    [self.cellsPool removeObject:cell];
    
    //更新瀑布流的总高度
    NSInteger scrollViewHeight = [self getTheHighestColumnHeight];
    if (scrollViewHeight > self.scrollViewHeight) {
        self.scrollViewHeight = scrollViewHeight;
        self.contentSize = CGSizeMake(self.frameWidth, self.scrollViewHeight);
    }
    
    self.workingInProgress = NO;
//    NSLog(@"++++++++++++++++++++++++++++++++>");
//    NSLog(@"[%@, %@, %@]", self.columnVisible[0][@"top"][@"y"], self.columnVisible[1][@"top"][@"y"], self.columnVisible[2][@"top"][@"y"]);
//    NSLog(@"[%@, %@, %@]", self.columnVisible[0][@"bottom"][@"y"], self.columnVisible[1][@"bottom"][@"y"], self.columnVisible[2][@"bottom"][@"y"]);
//    NSLog(@"[%@, %@, %@]", self.columnVisible[0][@"top"][@"indexInMatrix"], self.columnVisible[1][@"top"][@"indexInMatrix"], self.columnVisible[2][@"top"][@"indexInMatrix"]);
//    NSLog(@"[%@, %@, %@]", self.columnVisible[0][@"bottom"][@"indexInMatrix"], self.columnVisible[1][@"bottom"][@"indexInMatrix"], self.columnVisible[2][@"bottom"][@"indexInMatrix"]);
//    NSLog(@" ");
    return YES;
}

-(NSInteger)getIndexInData:(NSInteger)column originY:(float)y direction:(NSString *)direction
{
    
    __block NSInteger indexInData = -1;
//    NSLog(@"%d", self.countOfMatrix);
    [self.matrix[column] enumerateObjectsUsingBlock:^(NSDictionary *d , NSUInteger i, BOOL *stop) {
        float prevY = [@"down" isEqualToString:direction] ? [d[@"y"] floatValue] + [d[@"h"] floatValue] + self.columnSpace : [d[@"y"] floatValue];
        if (prevY == y) {
            indexInData = [d[@"indexInData"] intValue];
            *stop = YES;
        }
    }];
    if (indexInData == -1) {
        if (self.countOfMatrix < [self.data count]) {
            indexInData = self.countOfMatrix;
        }
    }
    return indexInData;
}

-(NSInteger)getIndexInMatrix:(NSInteger)column originY:(float)y
{
    NSInteger count = [self.matrix[column] count];
    NSInteger indexInMatrix = 0;
    for (NSInteger i = 0; i < count; i++) {
        if (y == [self.matrix[column][i][@"y"] floatValue]) {
            indexInMatrix = i;
        }
    }
    return indexInMatrix;
}

-(CGPoint)getOrigin:(NSString *)direction
{
    NSInteger x = self.columnSpace;
    id y;
    if ([@"up" isEqualToString:direction]) {
        y = self.columnVisible[0][@"bottom"][@"y"];
        for (NSInteger i = 1; i < self.columns; i++) {
            if ([self.columnVisible[i][@"bottom"][@"y"] floatValue] < [y floatValue]) {
                y = self.columnVisible[i][@"bottom"][@"y"];
                x = i * (self.columnWidth + self.columnSpace) + self.columnSpace;
            }
        }
    }
    if ([@"down" isEqualToString:direction]) {
        y = self.columnVisible[0][@"top"][@"y"];
        for (NSInteger i = 1; i < self.columns; i++) {
            if ([self.columnVisible[i][@"top"][@"y"] floatValue] > [y floatValue]) {
                y = self.columnVisible[i][@"top"][@"y"];
                x = i * (self.columnWidth + self.columnSpace) + self.columnSpace;
            }
        }
    }
    return CGPointMake(x, [y floatValue]);
}

-(NSInteger)getColumnNumberByX:(float)x
{
    return (x - self.columnSpace) / (self.columnSpace + self.columnWidth);
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //在滚动结束后再检查一次是否已经把当前可见区域的cells都画好了
    [self redrawVisibleScrollView];
}
-(void)redrawVisibleScrollView{
    NSString *direction = self.lastScrollDirection;
    BOOL result;
    if (self.workingInProgress) {
        return;
    }
    self.cellsToBeRemoved = [@[] mutableCopy];
    if ([@"up" isEqualToString:direction]) {
        NSInteger bottomLowestHeight = [self getTheLowestHeightForAddingCell];
        while (bottomLowestHeight <= self.currentOffsetY + self.frameHeight) {
            NSLog(@"%d--%d", bottomLowestHeight, self.currentOffsetY + self.frameHeight);

            NSLog(@"^^");
            result = [self renderCell:direction];
            if (!result) {
                break;
            }
            bottomLowestHeight = [self getTheLowestHeightForAddingCell];
        }
    }
    
    if([@"down" isEqualToString:direction]) {
        NSInteger topHighestHeight = [self getTheHighestHeightForAddingCell];
        while (topHighestHeight >= self.currentOffsetY) {
            NSLog(@"^^");
            result = [self renderCell:direction];
            if (!result) {
                break;
            }
            topHighestHeight = [self getTheHighestHeightForAddingCell];
        }
    }
    NSLog(@"contentSize height: %d", self.scrollViewHeight);  
}
-(NSInteger)getTheHighestColumnHeight
{
    id y = self.columnVisible[0][@"bottom"][@"y"];
    for (NSInteger i = 1; i < self.columns; i++) {
        if ([self.columnVisible[i][@"bottom"][@"y"] floatValue] > [y floatValue]) {
            y = self.columnVisible[i][@"bottom"][@"y"];
        }
    }
    return [y intValue];
}

-(NSInteger)getTheLowestHeightForAddingCell
{
    id y = self.columnVisible[0][@"bottom"][@"y"];
    for (NSInteger i = 1; i < self.columns; i++) {
        if ([self.columnVisible[i][@"bottom"][@"y"] floatValue] < [y floatValue]) {
            y = self.columnVisible[i][@"bottom"][@"y"];
        }
    }
    return [y intValue];
}

-(NSInteger)getTheHighestHeightForAddingCell
{
    id y = self.columnVisible[0][@"top"][@"y"];
    for (NSInteger i = 1; i < self.columns; i++) {
        if ([self.columnVisible[i][@"top"][@"y"] floatValue] > [y floatValue]) {
            y = self.columnVisible[i][@"top"][@"y"];
        }
    }
    return [y intValue];
}

-(void)reload{
    for(UIView *view in self.subviews){
        if([view isKindOfClass:[PLGViewCell class]]){
            [view removeFromSuperview];
        }
    }
    [self initProperties];
    self.contentSize = CGSizeMake(self.frameWidth, self.frameHeight + 1);
//    NSLog(@"reload =====%f", self.contentOffset.y );
    
    [self initContent];
    
}

-(NSMutableSet *)getPoolSet:(NSString *)identifier{
    NSMutableSet *set = self.cellsPools[identifier];
    if(set == nil){
        set = [NSMutableSet set];
        self.cellsPools[identifier] = set;
    }
    return set;
}
#pragma mark - public method
-(PLGViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier{
    NSMutableSet *set = [self getPoolSet:identifier];
//    NSLog(@"get reuse cell's count:%d", [set count]);
    PLGViewCell *cell = [set anyObject];
    if(cell){
        [set removeObject:cell];
    }
    return cell;
}

@end

#pragma mark - PLGViewCell
@implementation PLGViewCell
-(id)initWithReuseIdentifier:(NSString *)indentifier{
    self = [super init];
    if(self){
        self.reuseIdentifier = indentifier;
    }
    return self;
}
@end
