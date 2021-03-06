//
//  PLGView.h
//  PinterestLikeGridView
//
//  Created by Weilong Song on 11/23/12.
//  Copyright (c) 2012 Weilong Song. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLGView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic) NSInteger            columns;                  //瀑布流的列数
@property (nonatomic) NSInteger            columnSpace;              //Cell之间的间距
@property (nonatomic) NSInteger            columnWidth;              //Column的宽度, int型
@property (nonatomic) float                columnWidthF;             //Column的宽度, float型
@property (nonatomic) NSInteger            scrollViewHeight;         //瀑布流的总高度
@property (nonatomic) NSArray             *data;                     //瀑布流的数据
@property (nonatomic) NSMutableArray      *columnX;                  //存储每列的X坐标
@property (nonatomic) NSMutableArray      *columnVisible;            //存储目前可见区域的列信息
@property (nonatomic) NSMutableArray      *matrix;                   //存储瀑布流矩阵信息
@property (nonatomic) NSInteger            countOfMatrix;            //瀑布流矩阵里面cell的个数
@property (nonatomic) NSInteger            frameWidth;               //瀑布流外框的宽度
@property (nonatomic) NSInteger            frameHeight;              //瀑布流外框的高度
@property (nonatomic) NSMutableSet        *cellsPool;                //Cells池, 存储重用的Cells
@property (nonatomic) NSMutableSet        *visibleCellsPool;         //Cells池, 存储可见的Cells
@property (nonatomic) NSMutableArray      *cellsToBeRemoved;         //Cells池, 存储要移除的Cells
@property (nonatomic) NSInteger            currentOffsetY;           //当前scrollView的offsetY
@property (nonatomic) BOOL                 isScrollingSlow;          //计算速度: 是否滚动很慢? 慢就要开始插入cell, 以便浏览
@property (nonatomic) CGPoint              lastOffset;               //计算速度: 滚动中:上100ms的scrollView contentOffset
@property (nonatomic) NSTimeInterval       lastOffsetCapture;        //计算速度: 上一次捕获contentOffset的时间点
@property (nonatomic) BOOL                 isLastScrolledUp;         //计算滚动方向: 记录上一次的滚动方向
@property (nonatomic) CGPoint              offsetWillBeginDragging;  //计算滚动方向: 开始拖拽时候的offset记录下来
@property (nonatomic) BOOL                 workingInProgress;        //正在增减cell, 请勿打扰
@property (nonatomic) NSString            *lastScrollDirection;      //上一次滚动的方向

- (id)initWithConfig:(CGRect)frame                              //自定义的init方法, 可配置瀑布流参数
             columns:(NSInteger)columns
         columnSpace:(NSInteger)columnSpace
                data:(NSArray *)data;
@end
