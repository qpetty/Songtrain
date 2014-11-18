//
//  AnimatedCollectionViewFlowLayout.m
//  SongTrain
//`
//  Created by Brandon Leventhal on 10/3/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "AnimatedCollectionViewFlowLayout.h"
#import "AnimatedCollectionViewCell.h"

#define TRAIN_DROPDOWN_HEIGHT 18

@implementation AnimatedCollectionViewFlowLayout

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    if (itemIndexPath.row == 0) {
        attributes.frame = CGRectMake(0, TRAIN_DROPDOWN_HEIGHT, self.itemSize.width, self.itemSize.height);
    } else {
        attributes.frame = [self getCellFrameAtIndex:itemIndexPath];
        attributes.alpha = 0.0;
    }

    return attributes;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    
    attributes.frame = CGRectMake(0, (self.itemSize.height * (itemIndexPath.row - 1)) + self.itemSize.height, self.itemSize.width, self.itemSize.height);
    attributes.alpha = 0.0;
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {

    UICollectionViewLayoutAttributes *itemAttributes =
    [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    itemAttributes.frame = [self getCellFrameAtIndex:indexPath];
    itemAttributes.alpha = 1.0;
    return itemAttributes;
}

- (CGSize)collectionViewContentSize {
    return self.collectionView.frame.size;
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

- (CGRect)getCellFrameAtIndex:(NSIndexPath *)indexPath {
    return CGRectMake(0, (self.itemSize.height * indexPath.row) + self.itemSize.height + TRAIN_DROPDOWN_HEIGHT, self.itemSize.width, self.itemSize.height);
}
@end
