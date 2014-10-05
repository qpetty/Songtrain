//
//  AnimatedCollectionViewFlowLayout.m
//  SongTrain
//`
//  Created by Brandon Leventhal on 10/3/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "AnimatedCollectionViewFlowLayout.h"

@implementation AnimatedCollectionViewFlowLayout


- (UICollectionViewLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];

    NSLog(@"\nanimating\n");
    if (itemIndexPath.row == 0) {
        attributes.frame = CGRectMake(0, self.collectionView.frame.origin.y - (self.itemSize.height * itemIndexPath.row), 600, self.itemSize.height);
    }
    attributes.frame = CGRectMake(0, [self getCellFrameAtIndex:[NSIndexPath indexPathForRow:itemIndexPath.row - 1 inSection:0]].origin.y, 600, self.itemSize.height);
    //attributes.transform3D = CATransform3DMakeTranslation(0, -self.collectionView.bounds.size.height, 0);
    return attributes;
}



- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {

    UICollectionViewLayoutAttributes *itemAttributes =
    [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    itemAttributes.frame = [self getCellFrameAtIndex:indexPath];
    return itemAttributes;
}

- (CGSize)collectionViewContentSize {
    // Fix size later
    return CGSizeMake(self.collectionView.frame.size.width, (self.itemSize.height + 10) * [self.collectionView numberOfItemsInSection:0]);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{

    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:self.layoutInfo.count];
    
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementIdentifier,
                                                         NSDictionary *elementsInfo,
                                                         BOOL *stop) {
        [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath,
                                                          UICollectionViewLayoutAttributes *attributes,
                                                          BOOL *innerStop) {
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                [allAttributes addObject:attributes];
            }
        }];
    }];
    
    return allAttributes;
}

- (void)prepareLayout
{
    [super prepareLayout];
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    
    for (NSInteger item = 0; item < itemCount; item++) {
        indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        
        UICollectionViewLayoutAttributes *itemAttributes =
        [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        itemAttributes.frame = [self getCellFrameAtIndex:indexPath];
        
        cellLayoutInfo[indexPath] = itemAttributes;
    }
    
    
    newLayoutInfo[@"cell"] = cellLayoutInfo;
    
    self.layoutInfo = newLayoutInfo;
}

- (CGRect)getCellFrameAtIndex:(NSIndexPath *)indexPath {
    return CGRectMake(0, ((self.itemSize.height + 10) * indexPath.row) + self.itemSize.height, 600, self.itemSize.height);
}
@end
