PLGV
====

Pinterest Like Grid View - Water Fall View - UIScrollView - For iOS5 and below

设计思想:
其实就是把瀑布流想象成为一个矩阵，这个矩阵在设置好列数之类的配置之后就已经固定了，然后用二维数组把图片放在矩阵中，这样矩阵中每个元素（图片）的高宽位置就固定了。
这样可以在内存中生成这个数组（数组虽然是一个动态数组但是相对是静态）。
然后用的是UISet做一个池子用来存储和释放当前屏幕可见的图片，随着滚动要不停的存储和释放，存储其实就是从矩阵中根据当前可见范围来取出数据，释放就直接删掉就可以了。
这里面最容易晕的就是render和delete的逻辑。只要用好这个池子，对内存的利用就会很好，不会造成卡顿。
